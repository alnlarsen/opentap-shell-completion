using System.Threading;
using OpenTap;
using OpenTap.Cli;

namespace ShellCompletion
{
    public enum BrowsableEnum {
      [Display("Exclude Unbrowsable")]
      Exclude,
      [Display("Include Unbrowsable")]
      Include,
    }
    [Display("regenerate", "Write all possible completions in the current installation to $TAP_PATH/.tap-completions.json", Group: "completion")]
    public class Regenerate : ICliAction
    {
        [CommandLineArgument("browsable", Description = "Include completions for types and arguments with [Browsable(false)].")]
        public BrowsableEnum WithUnbrowsable { get; set; }
        public int Execute(CancellationToken cancellationToken)
        {
            CompletionRegenerator.RegenerateAction(WithUnbrowsable == BrowsableEnum.Include);
            return 0;
        }
    }
}

