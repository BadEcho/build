// -----------------------------------------------------------------------
// <copyright>
//      Created by Matt Weber <matt@badecho.com>
//      Copyright @ 2025 Bad Echo LLC. All rights reserved.
//
//      Bad Echo Technologies are licensed under the
//      GNU Affero General Public License v3.0.
//
//      See accompanying file LICENSE.md or a copy at:
//      https://www.gnu.org/licenses/agpl-3.0.html
// </copyright>
// -----------------------------------------------------------------------

using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Text.Json;
using System.Text.Json.Nodes;
using BadEcho.Build.Properties;
using Microsoft.Build.Framework;
using Microsoft.Build.Utilities;
using Task = Microsoft.Build.Utilities.Task;

namespace BadEcho.Build
{
    /// <summary>
    /// Provides an MSBuild task that will parse a JSON file and return metadata containing the contents of said file.
    /// </summary>
    public sealed class ReadJsonFile : Task
    {
        /// <summary>
        /// Gets or sets the path to the JSON file to parse.
        /// </summary>
        [Required]
        public string? Path 
        { get; set; }

        /// <summary>
        /// Gets the resulting task item whose metadata has been loaded with the JSON file's properties.
        /// </summary>
        [Output]
        public ITaskItem? Output 
        { get; private set; }

        /// <inheritdoc/>
        public override bool Execute()
        {
            if (string.IsNullOrEmpty(Path))
            {
                Log.LogErrorFromResources(nameof(Strings.NoPathProvided));
                return false;
            }

            JsonNode? content = JsonNode.Parse(File.ReadAllText(Path));

            if (content == null)
            {
                Log.LogErrorFromResources(nameof(Strings.JsonParseFailed), Path);
                return false;
            }

            JsonObject contentObject = content.AsObject();

            var taskItem = new TaskItem(contentObject.ToJsonString());

            AddPropertiesToItem(contentObject, taskItem);

            Output = taskItem;
            return true;
        }

        private static void AddPropertiesToItem(JsonObject jsonObject, TaskItem taskItem, string rootName = "")
        {
            IEnumerable<string> propertyNames = jsonObject.Select(kv => kv.Key);

            foreach (string propertyName in propertyNames)
            {
                JsonNode? property = jsonObject[propertyName];

                if (property?.GetValueKind() == JsonValueKind.Object)
                {
                    JsonObject propertyObject = property.AsObject();
                    AddPropertiesToItem(propertyObject, taskItem, $"{rootName}{propertyName}");
                }
                else
                {
                    taskItem.SetMetadata($"{rootName}{propertyName}", property?.GetValue<object>().ToString());
                }
            }
        }
    }
}
