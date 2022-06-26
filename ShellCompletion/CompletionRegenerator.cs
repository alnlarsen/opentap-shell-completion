using System.ComponentModel;
using System.IO;
using System.Linq;
using OpenTap;
using OpenTap.Cli;

namespace ShellCompletion
{
    class CompletionRegenerator
    {
        public static void RegenerateAction(bool withUnbrowsable)
        {
            var actions = TypeData.GetDerivedTypes<ICliAction>()
                .Where(a => a.CanCreateInstance);
            if (!withUnbrowsable)
                actions = actions.Where(a => a.GetAttribute<BrowsableAttribute>()?.Browsable != true);
            var tree = CompletionTree.FromActions(actions.Select(a => new TdDisp(a, a.GetDisplayAttribute()))
                                                         .ToArray(), withUnbrowsable, "tap", true);
            var tapPath = Path.GetDirectoryName(PluginManager.GetOpenTapAssembly().Location);
            var savepath = Path.Combine(tapPath, ".tap-completions.json");
            File.WriteAllText(savepath, tree.ToJson());
        }
    }
}
