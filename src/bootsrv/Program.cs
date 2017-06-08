using System;
using System.Collections.Generic;
using System.Configuration;
using System.IO;
using System.IO.Ports;
using System.Linq;
using System.Text;
using System.Threading;
using System.Threading.Tasks;

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

            Console.WriteLine("Buf: {0} bytes", port.BytesToWrite);
        }

        private static void HandleFileRequest(SerialPort port, byte packet)
        {
            bool is16Bit = ((packet >> 4) & 0x0F) == 0x02;
            int fileId = packet & 0x0F;
            Console.WriteLine("Received file request {0}", fileId);

            using (var stream = GetFileStream(fileId))
            {
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

                if (is16Bit)
                    Console.WriteLine("Sent file {0}, 16-bit mode, {1:X4} bytes total.", fileId, data.Length);
                else
                {
                    Console.WriteLine("Sent file {0}, 32-bit mode, {1:X4} bytes total.", fileId, data.Length);
                }
            }
        }

        private static Stream GetFileStream(int id)
        {
            string path = ConfigurationManager.AppSettings[$"File{id}"];
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
