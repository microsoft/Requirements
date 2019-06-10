using System;
using System.Management.Automation;

namespace Requirements
{

    public class Requirement
    {
        [ValidateNotNullOrEmpty()]
        public readonly string Name = "<unnamed>";
        [ValidateNotNullOrEmpty()]
        public readonly string Describe;
        [ValidateNotNullOrEmpty()]
        public readonly ScriptBlock Test;
        [ValidateNotNullOrEmpty()]
        public readonly ScriptBlock Set;
        [ValidateNotNullOrEmpty()]
        public readonly string[] DependsOn;
    }
}
