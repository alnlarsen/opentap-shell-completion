using System;
using System.Diagnostics;
using System.IO;
using OpenTap.Package;

namespace ShellCompletion
{
    class SubprocessGenerator
    {
        public static void Regenerate()
        {
            var installDir = Environment.GetEnvironmentVariable("TPM_PARENTPROCESSDIR", EnvironmentVariableTarget.Process);
            if (string.IsNullOrWhiteSpace(installDir))
              installDir = Path.GetDirectoryName(System.Reflection.Assembly.GetEntryAssembly().Location);
            var binary = Path.Combine(installDir, "tap");
            var opentap = Path.Combine(installDir, "OpenTap.dll");

            if (File.Exists(opentap))
            {
                Process.Start(binary, "completion regenerate");
            }
        }
    }
    
    public class RegenerateOnInstall : ICustomPackageAction
    {
        public int Order()
        {
            return 99999;
        }

        public bool Execute(PackageDef package, CustomPackageActionArgs customActionArgs)
        {
            SubprocessGenerator.Regenerate();
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
            SubprocessGenerator.Regenerate();
            return true;
        }

        public PackageActionStage ActionStage => PackageActionStage.Uninstall;
    }
}
