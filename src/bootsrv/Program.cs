using System;
using System.Configuration;
using System.IO;
using System.IO.Ports;
using System.Text;
using System.Threading;

namespace bootsrv
{
    public class Program
    {
        private static string ComPort => ConfigurationManager.AppSettings["SerialPort"];
        private static int BaudRate => int.Parse(ConfigurationManager.AppSettings["BaudRate"]);
        private static int WriteBufferSize => int.Parse(ConfigurationManager.AppSettings["WriteBufferSize"]);

        public static void Main(string[] args)
        {
            SerialPort port = new SerialPort(ComPort);
            port.DataBits = 8;
            port.StopBits = StopBits.One;
            port.BaudRate = BaudRate;
            port.Parity = Parity.None;
            port.Handshake = Handshake.None;
            port.WriteBufferSize = WriteBufferSize;
            port.Encoding = Encoding.ASCII;

            port.DtrEnable = true;
            port.RtsEnable = true;

            port.DataReceived += PortOnDataReceived;
            port.Open();

            Thread.Sleep(Timeout.Infinite);
        }

        private static void PortOnDataReceived(object sender, SerialDataReceivedEventArgs serialDataReceivedEventArgs)
        {
            SerialPort port = (SerialPort)sender;
            byte pkt = (byte)port.ReadByte();
            byte opcode = (byte)((pkt >> 4) & 0x0F);

            switch (opcode)
            {
                case 0x01:
                    HandleIdentification(port, pkt);
                    break;

                case 0x02:  // request file, 16-bits
                case 0x03:  // request file, 32-bits
                    HandleFileRequest(port, pkt);
                    break;

                default:
                    Console.WriteLine("Unknown packet opcode {0:X2}.", pkt);
                    break;
            }
        }

        private static void HandleIdentification(SerialPort port, byte packet)
        {
            Console.WriteLine("Received client identification packet {0:X2}.", packet);
            var idString = Encoding.ASCII.GetBytes("BOOTSRV1");

            // Send a server ID packet back.
            byte[] response = new byte[9];
            response[0] = 0b00010010;
            Array.Copy(idString, 0, response, 1, 8);
            port.Write(response, 0, 9);

            DumpHex(response, 9);
        }

        private static void HandleFileRequest(SerialPort port, byte packet)
        {
            bool is16Bit = ((packet >> 4) & 0x0F) == 0x02;
            bool isHighSpeed = ((packet >> 3) & 0x01) == 0x01;
            int fileId = packet & 0b111;

            Console.WriteLine("Received {0}file request {1}", isHighSpeed ? "high-speed " : string.Empty, fileId);

            if (isHighSpeed)
            {
                Console.Write("Giving client time to switch: ");
                for (int i=0;i<2;i++)
                {
                    Thread.Sleep(1000);
                    Console.Write(".");
                }
                Console.WriteLine();

                port.Close();
                port.BaudRate = 115200;
                port.Open();
            }

            using (var stream = GetFileStream(fileId))
            {
                if (stream == null)
                {
                    Console.WriteLine("File not found!");
                    return;
                }
                
                int size = (int)stream.Length;

                // Write size of file
                if (is16Bit)
                {
                    byte[] sizeBytes = BitConverter.GetBytes((ushort)size);
                    port.Write(sizeBytes, 0, 2);
                    DumpHex(sizeBytes, 2);
                }
                else
                {
                    byte[] sizeBytes = BitConverter.GetBytes((uint)size);
                    port.Write(sizeBytes, 0, 4);
                    DumpHex(sizeBytes, 4);
                }

                // Write data
                byte[] data = new byte[size];
                stream.Read(data, 0, size);
                port.Write(data, 0, data.Length);
                DumpHex(data, size);

                // Wait until the output buffer is empty.
                while (port.BytesToWrite != 0)
                    Thread.Yield();

                if (isHighSpeed)
                {
                    port.Close();
                    port.BaudRate = 9600;
                    port.Open();
                }

                Console.WriteLine("Sent file {0}, {2}-bit mode, {1:X4} bytes total.", fileId, data.Length, is16Bit ? "16" : "32");
            }
        }

        private static Stream GetFileStream(int id)
        {
            string path = ConfigurationManager.AppSettings[$"File{id}"];
            if (!File.Exists(path))
                return null;

            return File.Open(path, FileMode.Open);
        }

        private static void DumpHex(byte[] data, int len)
        {
            for (int i = 0; i < len; i++)
                Console.Write("{0:X2} ", data[i]);
            Console.WriteLine();
        }
    }
}
