using System.Threading;
using OpenTap.Cli;
using OpenTap;

namespace ShellCompletion
{
    [Display("regenerate", Description: "Regenerate the completion tree for this installation.", Groups: new[] { "completion" })]
    public class GenerateCompletionTree : ICliAction
    {
        public int Execute(CancellationToken cancellationToken)
        {
          var actions =           TypeData.GetDerivedTypes<ICliAction>();


          return 0;
        }
    }
}

