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

using System.Text.Json.Nodes;
using BadEcho.Build.Properties;
using Microsoft.Build.Framework;
using Microsoft.Build.Utilities;
using Task = Microsoft.Build.Utilities.Task;

namespace BadEcho.Build;

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
        IEnumerable<string> properties = contentObject.Select(kv => kv.Key);

        var taskItem = new TaskItem(contentObject.ToJsonString());

        foreach (string property in properties)
        {
            taskItem.SetMetadata(property, contentObject[property]?.GetValue<object>().ToString());
        }

        Output = taskItem;
        return true;
    }
}
