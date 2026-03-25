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

using System.Text;
using Microsoft.Build.Framework;
using Microsoft.Build.Utilities;

namespace BadEcho.Build
{
    /// <summary>
    /// Provides a task that will execute a Git command.
    /// </summary>
    public sealed class Git : ToolTask
    {
        private readonly StringBuilder _standardOutput = new StringBuilder();

        /// <summary>
        /// Gets or sets the Git command to execute.
        /// </summary>
        [Required]
        public string Command
        { get; set; }

        /// <summary>
        /// Gets or sets arguments to pass to the Git command.
        /// </summary>
        public string Arguments
        { get; set; }

        /// <summary>
        /// Gets the standard output of the Git command.
        /// </summary>
        [Output]
        public string Output
        { get; private set; }

        /// <inheritdoc/>
        protected override string ToolName
            => "git.exe";

        /// <inheritdoc/>
        public override bool Execute()
        {
            _ = ExecuteTool(GenerateFullPathToTool(), string.Empty, GenerateCommandLineCommands());

            if (!Log.HasLoggedErrors)
            {
                Output = _standardOutput.ToString().Trim();
            }

            return !Log.HasLoggedErrors;
        }

        /// <inheritdoc/>
        protected override string GenerateFullPathToTool()
            // The runtime will automatically search the system path for us.
            => ToolName;

        /// <inheritdoc/>
        protected override string GenerateCommandLineCommands()
        {
            var commandLine = new CommandLineBuilder();

            commandLine.AppendTextUnquoted(Command);

            if (!string.IsNullOrEmpty(Arguments))
                commandLine.AppendSwitch(Arguments);

            return commandLine.ToString();
        }

        /// <inheritdoc/>
        protected override void LogEventsFromTextOutput(string singleLine, MessageImportance messageImportance)
        {
            if (!string.IsNullOrEmpty(singleLine))
                _ = _standardOutput.AppendLine(singleLine);

            base.LogEventsFromTextOutput(singleLine, messageImportance);
        }
    }
}
