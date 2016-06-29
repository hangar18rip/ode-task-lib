using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.Linq;
using System.Management.Automation;
using System.Text;
using System.Threading.Tasks;

namespace ode.TaskLib.Powershell
{
    [Cmdlet(VerbsLifecycle.Start, "ProcessExtended")]
    public class StartProcessExtendedCmdLet : PSCmdlet
    {
        [Parameter(Mandatory = true, ValueFromPipeline = true, Position = 0)]
        public string FilePath { get; set; }

        [Parameter(Mandatory = false, ValueFromPipeline = false, Position = 1)]
        public string[] Arguments { get; set; }

        [Parameter(Mandatory = false, ValueFromPipeline = false, Position = 2)]
        public string WorkingDirectory { get; set; }


        protected override void ProcessRecord()
        {
            base.ProcessRecord();

            var si = new ProcessStartInfo(FilePath, string.Join(" ", Arguments));
            si.CreateNoWindow = true;
            si.UseShellExecute = false;
            si.RedirectStandardError = true;
            si.RedirectStandardOutput = true;
            si.WorkingDirectory = WorkingDirectory;
            var p = new Process();
            p.StartInfo = si;
            p.OutputDataReceived += OutputDataReceived;
            p.ErrorDataReceived += ErrorDataReceived;
            p.Start();
            p.BeginErrorReadLine();
            p.BeginOutputReadLine();
            p.WaitForExit((int)(new TimeSpan(1, 0, 0).TotalMilliseconds));

            WriteObject(p);

        }

        void OutputDataReceived(object sender, DataReceivedEventArgs e)
        {
            if (!string.IsNullOrEmpty(e.Data))
            {
                Host.UI.WriteLine(e.Data);
            }
        }

        void ErrorDataReceived(object sender, DataReceivedEventArgs e)
        {
            if (!string.IsNullOrEmpty(e.Data))
            {
                Host.UI.WriteErrorLine(e.Data);
            }
        }
    }
}
