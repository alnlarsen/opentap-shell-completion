using System.Collections.Generic;
using System.ComponentModel;
using System.Linq;
using Newtonsoft.Json;
using OpenTap;
using OpenTap.Cli;

namespace ShellCompletion
{
    public class FlagCompletion
    {
        public string Name { get; set; }
        public string ShortName { get; set; } = null;
        public string LongName { get; set; } = null;
        public string Description { get; set; }
        public string Type { get; set; }
        public string[] SuggestedCompletions { get; set; } = null;
    }

    public class CompletionTree
    {
        public string Name { get; set; }
        public bool IsTerminal { get; set; }

        /// <summary>
        /// These completions are hardcoded because they are not actually part of the API, but are hardcoded by the OpenTAP
        /// CLIActionExecutor and argument parser.
        /// </summary>
        public List<FlagCompletion> FlagCompletions { get; set; } = new List<FlagCompletion>
        {
            new FlagCompletion() { Name = "__BUILTIN_HELP__", ShortName = "h", LongName = "help", Type = "System.Boolean", Description = "Write help information." },
            new FlagCompletion() { Name = "__BUILTIN_VERBOSE__", ShortName = "v", LongName = "verbose", Type = "System.Boolean", Description = "Show verbose/debug-level log messages." },
            new FlagCompletion() { Name = "__BUILTIN_COLOR__", ShortName = "c", LongName = "color", Type = "System.Boolean", Description = "Color messages according to their severity." },
            new FlagCompletion() { Name = "__BUILTIN_LOG__", ShortName = null, LongName = "log", Type = "System.String", Description = "Specify log file location. Default is ./SessionLogs" },
        };

        public List<CompletionTree> Completions { get; set; } = new List<CompletionTree>();
        public static CompletionTree FromActions(ITypeData[] actions, bool withUnbrowsable)
        {
            var root = new CompletionTree
            {
                IsTerminal = true,
                Name = "tap"
            };
            
            // Parse out all the groups
            var assoc = actions.Select(a => (a, a.GetDisplayAttribute())).ToArray();
            foreach (var (td, disp) in assoc)
            {
                if (disp.Group == null || disp.Group.Length == 0)
                {
                    // These will all be terminal
                    try
                    {
                        var comp = new CompletionTree(td, withUnbrowsable)
                        {
                            Name = disp?.Name ?? td.Name,
                            IsTerminal = true
                        };
                        root.Completions.Add(comp);
                    }
                    catch
                    {
                        // this could not be constructed
                        // nothing we can do about it
                    }
                }
            }
            
            return root;
        }

        CompletionTree()
        {
        }

        public CompletionTree(ITypeData node, bool withUnbrowsable)
        {
            var instance = node.CreateInstance();
            var a = AnnotationCollection.Annotate(instance);

            var members = node.GetMembers().ToArray();
            foreach (var member in members)
            {
                if (member.Readable == false || member.Writable == false)
                    continue;

                var disp = member.GetDisplayAttribute();
                var unnamedCli = member.GetAttribute<UnnamedCommandLineArgument>();
                if (unnamedCli != null)
                {
                    
                    FlagCompletions.Add(new FlagCompletion()
                    {
                        Name = unnamedCli.Name,
                        LongName = null,
                        ShortName = null,
                        Type = member.TypeDescriptor.Name,
                        
                    });
                    continue;
                }
                if (!withUnbrowsable)
                {
                    if (member.GetAttribute<BrowsableAttribute>()?.Browsable == false)
                        continue;
                }

                var cli = member.GetAttribute<CommandLineArgumentAttribute>();
                if (cli == null) continue;
                if (!withUnbrowsable && cli.Visible == false) continue;
            }
        }

        public string ToJson()
        {
            return JsonConvert.SerializeObject(this);
        }
    }
}