using System;
using System.Collections;
using System.Collections.Generic;
using System.IO;
using System.IO.Compression;
using System.Linq;
using System.Text.RegularExpressions;
using System.Text;
using System.Reflection;
using System.Runtime.CompilerServices;
using System.Web.Script.Serialization;

internal static class SaveDecodeTool
{
    private static object ConvertSafe(object value, int depth, int maxDepth, int maxItems, HashSet<int> visited)
    {
        if (value == null)
        {
            return null;
        }

        var type = value.GetType();

        if (type.IsPrimitive || value is string || value is decimal)
        {
            return value;
        }

        if (value is DateTime dt)
        {
            return dt.ToString("o");
        }

        if (type.IsEnum)
        {
            return value.ToString();
        }

        if (depth >= maxDepth)
        {
            return "[MaxDepth:" + type.FullName + "]";
        }

        if (!type.IsValueType)
        {
            int id = RuntimeHelpers.GetHashCode(value);
            if (visited.Contains(id))
            {
                return "[Ref:" + type.FullName + ":" + id + "]";
            }
            visited.Add(id);
        }

        if (value is IDictionary dict)
        {
            var result = new Dictionary<string, object>();
            int count = 0;
            foreach (DictionaryEntry entry in dict)
            {
                if (count >= maxItems)
                {
                    result["__truncated"] = true;
                    break;
                }

                string key = entry.Key == null ? "<null>" : entry.Key.ToString();
                result[key] = ConvertSafe(entry.Value, depth + 1, maxDepth, maxItems, visited);
                count++;
            }
            return result;
        }

        if (value is IEnumerable enumerable && !(value is string))
        {
            var list = new List<object>();
            int count = 0;
            foreach (var item in enumerable)
            {
                if (count >= maxItems)
                {
                    list.Add("[Truncated]");
                    break;
                }
                list.Add(ConvertSafe(item, depth + 1, maxDepth, maxItems, visited));
                count++;
            }
            return list;
        }

        var objResult = new Dictionary<string, object>();
        objResult["__type"] = type.FullName;

        foreach (var prop in type.GetProperties(BindingFlags.Public | BindingFlags.Instance))
        {
            if (prop.GetIndexParameters().Length > 0)
            {
                continue;
            }

            try
            {
                object propValue = prop.GetValue(value, null);
                objResult[prop.Name] = ConvertSafe(propValue, depth + 1, maxDepth, maxItems, visited);
            }
            catch (Exception ex)
            {
                objResult[prop.Name] = "[Error:" + ex.Message + "]";
            }
        }

        foreach (var field in type.GetFields(BindingFlags.Public | BindingFlags.NonPublic | BindingFlags.Instance))
        {
            if (objResult.ContainsKey(field.Name))
            {
                continue;
            }

            try
            {
                object fieldValue = field.GetValue(value);
                objResult[field.Name] = ConvertSafe(fieldValue, depth + 1, maxDepth, maxItems, visited);
            }
            catch (Exception ex)
            {
                objResult[field.Name] = "[Error:" + ex.Message + "]";
            }
        }

        return objResult;
    }

    private static string[] ExtractAsciiStrings(byte[] data, int minLen)
    {
        var results = new HashSet<string>(StringComparer.Ordinal);

        string ascii = Encoding.ASCII.GetString(data);
        string utf8 = Encoding.UTF8.GetString(data);
        string utf16 = Encoding.Unicode.GetString(data);

        string pattern = @"[\x20-\x7E]{" + minLen + @",}";

        foreach (string text in new[] { ascii, utf8, utf16 })
        {
            foreach (Match match in Regex.Matches(text, pattern))
            {
                string token = match.Value.Trim();
                if (token.Length >= minLen)
                {
                    results.Add(token);
                }
            }
        }

        return results.ToArray();
    }

    public static int Main(string[] args)
    {
        try
        {
            string savePath = args.Length > 0 ? args[0] : null;
            string outPath = args.Length > 1 ? args[1] : null;
            string gamePath = args.Length > 2 ? args[2] : @"D:\Steam\steamapps\common\UBOAT";

            if (string.IsNullOrWhiteSpace(savePath))
            {
                string saveDir = Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.UserProfile), "AppData", "LocalLow", "Deep Water Studio", "UBOAT", "Saves");
                var latestManual = new DirectoryInfo(saveDir)
                    .GetFiles("*.save")
                    .Where(f => !f.Name.StartsWith("Autosave_", StringComparison.OrdinalIgnoreCase))
                    .OrderByDescending(f => f.LastWriteTime)
                    .FirstOrDefault();

                if (latestManual == null)
                {
                    Console.Error.WriteLine("No manual save found.");
                    return 2;
                }

                savePath = latestManual.FullName;
            }

            if (string.IsNullOrWhiteSpace(outPath))
            {
                string baseDir = AppDomain.CurrentDomain.BaseDirectory;
                outPath = Path.GetFullPath(Path.Combine(baseDir, "latest-manual-savegame-decoded.json"));
            }

            string managedDir = Path.Combine(gamePath, "UBOAT_Data", "Managed");
            string gameAsmPath = Path.Combine(managedDir, "com.uboat.game.dll");

            if (!File.Exists(savePath))
            {
                Console.Error.WriteLine("Save not found: " + savePath);
                return 2;
            }

            if (!File.Exists(gameAsmPath))
            {
                Console.Error.WriteLine("Game assembly not found: " + gameAsmPath);
                return 2;
            }

            AppDomain.CurrentDomain.AssemblyResolve += (sender, eventArgs) =>
            {
                string asmName = new AssemblyName(eventArgs.Name).Name + ".dll";
                string candidate = Path.Combine(managedDir, asmName);
                return File.Exists(candidate) ? Assembly.LoadFrom(candidate) : null;
            };

            byte[] gameStateBytes;
            byte[] screenshotBytes = new byte[0];
            int gameStateLen;
            int screenshotLen = 0;

            if (savePath.EndsWith(".bin", StringComparison.OrdinalIgnoreCase))
            {
                gameStateBytes = File.ReadAllBytes(savePath);
                gameStateLen = gameStateBytes.Length;
            }
            else
            {
                using (var fs = File.OpenRead(savePath))
                using (var deflate = new DeflateStream(fs, CompressionMode.Decompress))
                using (var reader = new BinaryReader(deflate))
                {
                    gameStateLen = reader.ReadInt32();
                    gameStateBytes = reader.ReadBytes(gameStateLen);
                    screenshotLen = reader.ReadInt32();
                    screenshotBytes = reader.ReadBytes(screenshotLen);
                }
            }

            Assembly gameAsm = Assembly.LoadFrom(gameAsmPath);
            Type settingsType = gameAsm.GetType("UBOAT.Game.Core.Serialization.GameStateSerializationSettings", true);
            Type deserializerType = gameAsm.GetType("UBOAT.Game.Serialization.GameStateDeserializer", true);

            object settings = Activator.CreateInstance(settingsType);
            object deserializer = Activator.CreateInstance(deserializerType, new[] { settings });
            MethodInfo deserialize = deserializerType.GetMethod("Deserialize", new[] { typeof(Stream), typeof(bool) });

            object decoded;
            string decodeError = null;
            try
            {
                using (var ms = new MemoryStream(gameStateBytes))
                {
                    decoded = deserialize.Invoke(deserializer, new object[] { ms, true });
                }
            }
            catch (Exception ex)
            {
                decoded = null;
                decodeError = ex.ToString();
            }

            var root = new Dictionary<string, object>
            {
                ["generatedAt"] = DateTime.Now.ToString("s"),
                ["sourceSave"] = savePath,
                ["sourceSaveName"] = Path.GetFileName(savePath),
                ["sourceSaveSizeBytes"] = new FileInfo(savePath).Length,
                ["gameStateBlockBytes"] = gameStateLen,
                ["screenshotBlockBytes"] = screenshotLen,
                ["screenshotJpegSignature"] = screenshotBytes.Length >= 3 && screenshotBytes[0] == 0xFF && screenshotBytes[1] == 0xD8 && screenshotBytes[2] == 0xFF
            };

            if (decoded != null)
            {
                root["decodeStrategy"] = "GameStateDeserializer.Deserialize(stream,true)";
                root["decodedRootType"] = decoded.GetType().FullName;
                root["decoded"] = ConvertSafe(decoded, 0, 8, 200, new HashSet<int>());
            }
            else
            {
                var allStrings = ExtractAsciiStrings(gameStateBytes, 4);
                string version = allStrings.FirstOrDefault(s => Regex.IsMatch(s, @"^\d{4}\.\d+\s+Patch\s+\d+", RegexOptions.IgnoreCase));
                string uboatType = allStrings.FirstOrDefault(s => s.StartsWith("Entities/Type ", StringComparison.OrdinalIgnoreCase));
                string shipName = allStrings.FirstOrDefault(s => Regex.IsMatch(s, @"^U-\d+", RegexOptions.IgnoreCase));
                string missionPath = allStrings.FirstOrDefault(s => s.StartsWith("Missions/", StringComparison.OrdinalIgnoreCase));
                string missionCode = allStrings.FirstOrDefault(s => Regex.IsMatch(s, @"^[A-Z]{2}\d+\s*-\s*[A-Z]{2}\d+", RegexOptions.IgnoreCase));
                string regionName = allStrings.FirstOrDefault(s => s.IndexOf("Atlantic", StringComparison.OrdinalIgnoreCase) >= 0 || s.IndexOf("Sea", StringComparison.OrdinalIgnoreCase) >= 0);
                string skipperName = allStrings.FirstOrDefault(s => s.EndsWith(";", StringComparison.Ordinal) && s.IndexOf(" ", StringComparison.Ordinal) > 0);

                string[] modIds = allStrings
                    .Where(s => s.StartsWith("uboat.", StringComparison.OrdinalIgnoreCase) || s.EndsWith("mod\\", StringComparison.OrdinalIgnoreCase))
                    .Take(50)
                    .ToArray();

                root["decodeStrategy"] = "Fallback ASCII extraction";
                root["decodeError"] = decodeError;
                root["extractedAsciiStringCount"] = allStrings.Length;
                root["parsedSummary"] = new Dictionary<string, object>
                {
                    ["version"] = version,
                    ["uboatType"] = uboatType,
                    ["shipName"] = shipName,
                    ["missionPath"] = missionPath,
                    ["missionCode"] = missionCode,
                    ["regionName"] = regionName,
                    ["skipperName"] = skipperName,
                    ["modIds"] = modIds
                };
                root["interestingAsciiStrings"] = allStrings
                    .Where(s => s.IndexOf("Type", StringComparison.OrdinalIgnoreCase) >= 0
                             || s.IndexOf("UBoat", StringComparison.OrdinalIgnoreCase) >= 0
                             || s.IndexOf("Mission", StringComparison.OrdinalIgnoreCase) >= 0
                             || s.IndexOf("Skipper", StringComparison.OrdinalIgnoreCase) >= 0
                             || s.IndexOf("mod", StringComparison.OrdinalIgnoreCase) >= 0)
                    .Take(300)
                    .ToArray();
                root["allAsciiStrings"] = allStrings;
            }

            var serializer = new JavaScriptSerializer { MaxJsonLength = int.MaxValue, RecursionLimit = 200 };
            string json = serializer.Serialize(root);
            File.WriteAllText(outPath, json);

            Console.WriteLine("Wrote: " + outPath);
            Console.WriteLine("Strategy: " + root["decodeStrategy"]);
            return 0;
        }
        catch (Exception ex)
        {
            Console.Error.WriteLine(ex);
            return 1;
        }
    }
}
