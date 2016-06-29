using System;
using Microsoft.VisualStudio.TestTools.UnitTesting;
using System.Management.Automation.Runspaces;
using System.Diagnostics;

namespace ode.TaskLib.Powershell.UnitTests
{
    [TestClass]
    public class StartProcessExtendedCmdLetTests
    {
        static Runspace runspace;
        Pipeline pipe;
        Command command;

        [ClassInitialize]
        public static void TestFixtureSetup(TestContext context)
        {
            Trace.TraceInformation("{0}", context.FullyQualifiedTestClassName);

            var config = RunspaceConfiguration.Create();

            config.Cmdlets.Append(new CmdletConfigurationEntry("Start-ProcessExtended", typeof(StartProcessExtendedCmdLet), ""));
            runspace = RunspaceFactory.CreateRunspace(config);
            runspace.Open();
        }

        [ClassCleanup]
        public static void TestFixtureTeardown()
        {
            runspace.Close();
        }

        [TestInitialize]
        public void Setup()
        {
            pipe = runspace.CreatePipeline();
            command = new Command("Start-ProcessExtended");
            pipe.Commands.Add(command);
        }

        [TestMethod]
        public void StartProcessExtendedCmdLet_Ping_LocalHost()
        {
            command.Parameters.Clear();
            command.Parameters.Add(new CommandParameter("FilePath", "ping"));
            command.Parameters.Add(new CommandParameter("Arguments", new string[] { "localhost" }));

            var res = pipe.Invoke();
            Assert.AreEqual(1, res.Count);
        }
    }
}
