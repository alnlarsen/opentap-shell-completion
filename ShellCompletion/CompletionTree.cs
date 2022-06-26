using System.Collections.Generic;
using System.ComponentModel;
using System.Linq;
using Newtonsoft.Json;
using OpenTap;
using OpenTap.Cli;

namespace ShellCompletion
{
    public class TdDisp
    {
        public ITypeData td;
        public DisplayAttribute disp;

        public TdDisp(ITypeData td, DisplayAttribute disp)
        {
            this.td = td;
            this.disp = disp;
        }
    }
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
        private static TraceSource log = Log.CreateSource(nameof(CompletionRegenerator));
        public string Name { get; set; }
        public string Description { get; set; }
        public bool IsTerminal { get; set; } = false;

        /// <summary>
        /// These completions are hardcoded because they are not actually part of the API, but are hardcoded by the OpenTAP
        /// CLIActionExecutor and argument parser.
        /// </summary>
        public List<FlagCompletion> FlagCompletions { get; set; } = new List<FlagCompletion>
        {
        };

        public List<CompletionTree> Completions { get; set; } = new List<CompletionTree>();
        public static CompletionTree FromActions(TdDisp[] actions, bool withUnbrowsable, string name, bool isTerminal)
        {
            var root = new CompletionTree
            {
                IsTerminal = isTerminal,
                Name = name
            };

            if (isTerminal)
            {
                root.FlagCompletions = new List<FlagCompletion>(){
                    new FlagCompletion() { Name = "__BUILTIN_HELP__", ShortName = "h", LongName = "help", Type = "System.Boolean", Description = "Write help information." },
                    new FlagCompletion() { Name = "__BUILTIN_VERBOSE__", ShortName = "v", LongName = "verbose", Type = "System.Boolean", Description = "Show verbose/debug-level log messages." },
                    new FlagCompletion() { Name = "__BUILTIN_COLOR__", ShortName = "c", LongName = "color", Type = "System.Boolean", Description = "Color messages according to their severity." },
                    new FlagCompletion() { Name = "__BUILTIN_LOG__", ShortName = null, LongName = "log", Type = "System.String", Description = "Specify log file location. Default is ./SessionLogs" },
                };
            }

            // Parse out all the groups
            foreach (var tddisp in actions)
            {
                var disp = tddisp.disp;
                var td = tddisp.td;
                if (disp.Group == null || disp.Group.Length == 0)
                {
                    // These will all be terminal
                    try
                    {
                        var comp = new CompletionTree(td, withUnbrowsable)
                        {
                            Name = disp?.Name ?? td.Name,
                            Description = disp?.Description,
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

            actions = actions.Where(a => a.disp.Group.Length > 0).ToArray();

            foreach (var grp in actions.GroupBy(a => a.disp.Group.First()))
            {
                var key = grp.Key;
                foreach (var member in grp)
                {
                    member.disp = new DisplayAttribute(member.disp.Name, member.disp.Description, Groups: member.disp.Group.Skip(1).ToArray());
                }
                var subtree = FromActions(grp.ToArray(), withUnbrowsable, key, false);
                root.Completions.Add(subtree);
            }



            return root;
        }

        CompletionTree()
        {
        }

        public CompletionTree(ITypeData node, bool withUnbrowsable)
        {
            FlagCompletions = new List<FlagCompletion>(){
                new FlagCompletion() { Name = "__BUILTIN_HELP__", ShortName = "h", LongName = "help", Type = "System.Boolean", Description = "Write help information." },
                new FlagCompletion() { Name = "__BUILTIN_VERBOSE__", ShortName = "v", LongName = "verbose", Type = "System.Boolean", Description = "Show verbose/debug-level log messages." },
                new FlagCompletion() { Name = "__BUILTIN_COLOR__", ShortName = "c", LongName = "color", Type = "System.Boolean", Description = "Color messages according to their severity." },
                new FlagCompletion() { Name = "__BUILTIN_LOG__", ShortName = null, LongName = "log", Type = "System.String", Description = "Specify log file location. Default is ./SessionLogs" }};


            var instance = node.CreateInstance();
            var a = AnnotationCollection.Annotate(instance);

            var lookup = a.Get<IMembersAnnotation>().Members.ToLookup(m => m.Get<IMemberAnnotation>().Member.Name);

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
                        Name = member.Name,
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

                var suggestions = new List<string>();

                try
                {
                    var mem = lookup[member.Name].FirstOrDefault();

                    // first add AvailableValues
                    var available = mem.Get<IAvailableValuesAnnotationProxy>()?.AvailableValues;
                    if (available != null)
                    {
                        foreach (var avail in available)
                        {
                            var sval = avail.Get<IStringValueAnnotation>()?.Value ?? avail.Get<IObjectValueAnnotation>()?.ToString();
                            if (!string.IsNullOrWhiteSpace(sval))
                                suggestions.Add(sval);
                        }
                    }

                    // then add suggested values
                    available = mem.Get<ISuggestedValuesAnnotationProxy>()?.SuggestedValues;
                    if (available != null)
                    {
                        suggestions.AddRange(available.Cast<object>().Select(v => v.ToString()));
                        foreach (var avail in available)
                        {
                            var sval = avail.Get<IStringValueAnnotation>()?.Value ?? avail.Get<IObjectValueAnnotation>()?.ToString();
                            if (!string.IsNullOrWhiteSpace(sval))
                                suggestions.Add(sval);
                        }
                    }

                    suggestions = suggestions.Distinct().ToList();
                }
                catch
                {
                    log.Warning($"Error while parsing available / suggested values for member {member.Name}.");
                }

                var comp = new FlagCompletion()
                {
                    Name = member.Name,
                    LongName = cli.Name,
                    ShortName = cli.ShortName,
                    Description = cli.Description,
                    Type = member.TypeDescriptor.Name,
                    SuggestedCompletions = suggestions.Any() ? suggestions.ToArray() : null
                };
                FlagCompletions.Add(comp);
            }
        }

        public string ToJson()
        {
            return JsonConvert.SerializeObject(this);
        }
    }
}
