package com.roohoo.flex.helpers.ipaddress
{
	import flash.utils.ByteArray;
	
	public class IPv6Address
	{
		
		public function IPv6Address(value:Object = null)
		{
			this.parse(value);
		}
		
		public static function toStringFirstByte(byte:uint):String
		{
			return byte != 0 ? byte.toString(16).toUpperCase() : '';
		}
		
		public static function toStringSecondByte(byte:uint, fixLength:Boolean = false):String
		{
			var str:String = byte.toString(16);
			if (fixLength && str.length == 1) {
				str = '0' + str;
			}
			return str.toUpperCase();
		}

		public function toString():String
		{
			var out:Array = [];
			for (var i:uint = 0; i < 8; i++) {
				var byteIndex:uint = i * 2;
				var group:String = toStringFirstByte(bytes[byteIndex]) +
									toStringSecondByte(bytes[byteIndex + 1], (bytes[byteIndex] != 0));
				out.push(group);
			}
			return out.join(':');
		}

		public function parse(input:Object):void
		{
			if(input == null)
			{
				clear();
				return;
			}
			else if(input is ByteArray)
			{
				var byteInput:ByteArray = ByteArray(input);
				if(byteInput.length == 16)
				{
					_bytes = new ByteArray();
					_bytes.writeBytes(byteInput);
				}
				else
				{
					clear();
					return;
				}
			}
			else
			{
				var addrString:String = input.toString();
				var parsedBytes:ByteArray = new ByteArray();
				var parts:Array = addrString.split(':');
				if(parts.length != 8)
				{
					clear();
					return;
				}
				
				for each(var part:String in parts)
				{
					while (part.length < 4) {
						part = '0' + part;
					}
					
					if (part.length != 4) {
						clear();
						return;
					}
					
					var byte1:int = parseInt(part.substr(0, 2), 16);
					var byte2:int = parseInt(part.substr(2, 2), 16);
					if(byte1 < 0 || byte1 > 255 || byte2 < 0 || byte2 > 255)
					{
						clear();
						return;
					}
					
					parsedBytes.writeByte(byte1);
					parsedBytes.writeByte(byte2);
				}
				
				_bytes = parsedBytes; 
			}
		}

		private var _bytes:ByteArray;

		public function get bytes():ByteArray
		{
			return _bytes;
		}

		public function set bytes(value:ByteArray):void
		{
			if(value.length != 16)
			{
				clear();
			}
			_bytes = value;
		}

		private function clear():void
		{
			_bytes = new ByteArray();
			for (var i:uint = 0; i < 16; i++) {
				_bytes.writeByte(0);
			}
		}
	}
}