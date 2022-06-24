using System.Diagnostics;
using System.Threading;
using OpenTap;
using OpenTap.Cli;

namespace ShellCompletion
{
    [Display("regenerate", "Write all possible completions in the current installation to $TAP_PATH/.tap-completions.json", Group: "completion")]
    public class GenerateCompletionTree : ICliAction
    {
        [CommandLineArgument("with-unbrowsable", Description = "Include completions for types and arguments with [Browsable(false)].")]
        public bool WithUnbrowsable { get; set; }
        public int Execute(CancellationToken cancellationToken)
        {
            CompletionRegenerator.RegenerateAction(WithUnbrowsable);
            return 0;
        }
    }
}

