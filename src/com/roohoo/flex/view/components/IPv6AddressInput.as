package com.roohoo.flex.view.components
{
	import com.roohoo.flex.helpers.ipaddress.IPv6Address;
	
	import flash.events.Event;
	import flash.events.FocusEvent;
	import flash.events.KeyboardEvent;
	
	import mx.events.FlexEvent;
	
	import spark.components.Label;
	import spark.components.TextInput;

	[Event(name="change", type="flash.events.Event")]
	
	[DefaultBindingProperty(source="value", destination="value")]
	
	public class IPv6AddressInput extends MultiFieldInput
	{
		public static const DIVIDER:String = ':';
		public static const FIELD_COUNT:uint = 8;
		public static const FIELD_MAX_CHARS:uint = 4;
		public static const FIELD_RESTRICT:String = '[0-9A-Fa-f]';
		public static const FIELD_MAX_VALUE:uint = 65535;
		
		public function IPv6AddressInput()
		{
			super();
			
			fieldCount = FIELD_COUNT;
		}
		
		protected var separators:Array = [];
		
		private var _value:IPv6Address = new IPv6Address();
		
		[Bindable("valueCommit")]
		public function get value():Object
		{
			return _value;
		}
		
		public function set value(address:Object):void
		{
			_value = new IPv6Address();
			_value.parse(address);
			invalidateProperties();
			dispatchEvent(new FlexEvent(FlexEvent.VALUE_COMMIT));
		}
		
		override protected function createChildren():void
		{
			super.createChildren();
			
			for (var i:uint = 1, len:uint = textFields.length; i < len; i++)
			{
				var index:uint = getElementIndex(textFields[i]);
				var separatorField:Label = new Label();
				separatorField.text = DIVIDER;
				addElementAt(separatorField, index);
				separators.push(separatorField);
			}
			
			for each (var textField:TextInput in textFields)
			{
				textField.width = FIELD_MAX_CHARS * 10;
				textField.restrict = FIELD_RESTRICT;
				textField.maxChars = FIELD_MAX_CHARS;
				textField.addEventListener(FocusEvent.FOCUS_OUT, textFieldFocusOutHandler);
				textField.addEventListener(Event.CHANGE, textFieldChangeHandler);
			}
		}
		
		protected function setTextValue(textField:TextInput, byte1:int, byte2:int):void
		{
			textField.text = IPv6Address.toStringFirstByte(byte1) +
								IPv6Address.toStringSecondByte(byte2, (byte1 != 0));
		}
		
		override protected function commitProperties():void
		{
			super.commitProperties();
			
			for (var i:uint = 0, len:uint = textFields.length; i < len; i++)
			{
				setTextValue(textFields[i], value.bytes[2 * i], value.bytes[2 * i + 1]);
			}
		}
		
		protected function textFieldFocusOutHandler(event:FocusEvent):void
		{
			var textField:TextInput = event.currentTarget as TextInput;
			var byteIndex:int = 2 * textFields.indexOf(textField);
			setTextValue(textField, value.bytes[byteIndex], value.bytes[byteIndex + 1]);
		}
		
		override protected function textFieldChangeHandler(event:Event):void
		{
			super.textFieldChangeHandler(event);
			
			var textField:TextInput = event.currentTarget as TextInput;
			var byteIndex:int = 2 * textFields.indexOf(textField);
			var bytes:Array = [ 0, 0 ];
			var idx:int = 1;
			var byteStr:String = '';
			for (var i:int = textField.text.length - 1; i >= 0; i--) {
				byteStr = textField.text.charAt(i) + byteStr;
				if (byteStr.length >= 2 || i == 0) {
					bytes[idx] = parseInt(byteStr, 16);
					idx--;
					byteStr = '';
				}
			}
			for each (var byte:String in bytes) {
				value.bytes[byteIndex++] = byte;
			}
			
			dispatchEvent(new FlexEvent(FlexEvent.VALUE_COMMIT));
			dispatchEvent(new Event(Event.CHANGE));
			
			if (textField.text.length >= FIELD_MAX_CHARS)
			{
				focusNextTextField(textField);
			}
		}
		
		override protected function keyDownNavigationHandler(event:KeyboardEvent):void
		{
			var textField:TextInput = event.currentTarget as TextInput;
			var dot:String = DIVIDER;
			if (event.charCode == dot.charCodeAt(0) &&
				textField.selectionActivePosition == textField.selectionAnchorPosition &&
				textField.selectionActivePosition == textField.text.length)
			{
				this.focusNextTextField(textField);
			}
			
			super.keyDownNavigationHandler(event);
		}
	}
}