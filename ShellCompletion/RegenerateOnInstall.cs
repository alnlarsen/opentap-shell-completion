using OpenTap.Package;

namespace ShellCompletion
{
    public class RegenerateOnInstall : ICustomPackageAction
    {
        public int Order()
        {
            return 99999;
        }

        public bool Execute(PackageDef package, CustomPackageActionArgs customActionArgs)
        {
            CompletionRegenerator.RegenerateAction(true);
            return true;
        }

        public PackageActionStage ActionStage => PackageActionStage.Install;
    }

    public class RegenerateOnUninstall : ICustomPackageAction
    {
        public int Order()
        {
            return 99999;
        }

        public bool Execute(PackageDef package, CustomPackageActionArgs customActionArgs)
        {
            CompletionRegenerator.RegenerateAction(true);
            return true;
        }

        public PackageActionStage ActionStage => PackageActionStage.Uninstall;
    }
}