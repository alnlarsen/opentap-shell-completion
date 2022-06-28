using System;
using System.Diagnostics;
using System.IO;
using OpenTap.Package;

namespace ShellCompletion
{
    static class Regenerator
    {
        static string GetInstallPath()
        {
            var installDir = Environment.GetEnvironmentVariable("TPM_PARENTPROCESSDIR", EnvironmentVariableTarget.Process);
            if (string.IsNullOrWhiteSpace(installDir))
                installDir = Path.GetDirectoryName(System.Reflection.Assembly.GetEntryAssembly().Location);
            return installDir;
        }
        public static void Regenerate()
        {
            var installDir = GetInstallPath();
            var cache = Path.Combine(installDir, ".tap-completions.json");

            try
            {
                if (File.Exists(cache))
                    File.Delete(cache);
            }
            catch
            {
                // This is probably ok, and we can't do anything about it anyway
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
            Regenerator.Regenerate();
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
            Regenerator.Regenerate();
            return true;
        }

        public PackageActionStage ActionStage => PackageActionStage.Uninstall;
    }
}
