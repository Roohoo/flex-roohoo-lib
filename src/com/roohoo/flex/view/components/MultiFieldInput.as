package com.roohoo.flex.view.components
{
	import flash.display.DisplayObject;
	import flash.events.Event;
	import flash.events.FocusEvent;
	import flash.events.KeyboardEvent;
	import flash.ui.Keyboard;
	
	import mx.events.FlexEvent;
	import mx.managers.IFocusManagerComponent;
	
	import spark.components.BorderContainer;
	import spark.components.TextInput;
	import spark.layouts.HorizontalLayout;
	
	[Event(name="enter", type="mx.events.FlexEvent")]
	
	[DefaultTriggerEvent("change")]
	
	public class MultiFieldInput extends BorderContainer implements IFocusManagerComponent
	{
		public function MultiFieldInput()
		{
			super();
			
			minWidth = 22;
			minHeight = 22;
			
			applyLayout();
		}
		
		protected function applyLayout():void
		{
			layout = new HorizontalLayout();
			(layout as HorizontalLayout).gap = 0;
			(layout as HorizontalLayout).verticalAlign = 'middle';
		}
		
		protected var fieldCount:int = 1;
		
		protected var textFields:Array = [];
		
		protected var enabledChanged:Boolean = false;
		
		[Inspectable(category="General", enumeration="true,false", defaultValue="true")]
		override public function set enabled(value:Boolean):void
		{
			if(value == enabled)
			{
				return;
			}
			
			super.enabled = value;
			enabledChanged = true;
			
			invalidateProperties();
		}
		
		
		private var _editable:Boolean = true;
		
		protected var editableChanged:Boolean = false;
		
		[Bindable("editableChanged")]
		[Inspectable(category="General", defaultValue="true")]
		public function get editable():Boolean
		{
			return _editable;
		}
		
		public function set editable(value:Boolean):void
		{
			if(value == _editable)
			{
				return;
			}
			
			_editable = value;
			editableChanged = true;
			
			invalidateProperties();
			
			dispatchEvent(new Event("editableChanged"));
		}
		
		private var _parentDrawsFocus:Boolean = false;
		
		public function get parentDrawsFocus():Boolean
		{
			return _parentDrawsFocus;
		}
		
		public function set parentDrawsFocus(value:Boolean):void
		{
			_parentDrawsFocus = value;
		}
		
		override protected function createChildren():void
		{
			super.createChildren();
			
			for (var i:int = 0; i < fieldCount; i++)
			{
				var textField:TextInput = new TextInput();
				textField.enabled = enabled;
				textField.setStyle('borderVisible', false);
				//textField.setStyle('focusAlpha', 0);
				
				textField.addEventListener(FocusEvent.FOCUS_IN, textFieldFocusInHandler);
				textField.addEventListener(KeyboardEvent.KEY_DOWN, keyDownNavigationHandler, false, 1000);
				textField.addEventListener(Event.CHANGE, textFieldChangeHandler);
				
				addElement(textField);
				textFields.push(textField);
			}
		}
		
		override protected function commitProperties():void
		{
			super.commitProperties();
			
			if(enabledChanged || editableChanged)
			{
				for each (var textField:TextInput in textFields) {
					if(enabledChanged)
					{
						textField.enabled = enabled;
					}
					textField.selectable = enabled;
				}
				
				enabledChanged = false;
				editableChanged = false;
			}
		}
		
		override protected function isOurFocus(target:DisplayObject):Boolean
		{
			for each (var textField:TextInput in textFields)
			{
				if(target == textField)
				{
					return true;
				}
			}
			return super.isOurFocus(target);
		}
		
		protected function focusNextTextField(textField:TextInput):void
		{
			var index:int = textFields.indexOf(textField);
			if(index < 0) throw new ArgumentError("Invalid text field");
			
			if(index == textFields.length - 1) return;
			else index++;
			
			textField = textFields[index] as TextInput;
			
			this.callLater(textField.setFocus);
		}
		
		protected function focusPreviousTextField(textField:TextInput):void
		{
			var index:int = textFields.indexOf(textField);
			if(index < 0) throw new ArgumentError("Invalid text field");
			
			if(index == 0) return;
			else index--;
			
			textField = textFields[index] as TextInput;
			
			this.callLater(textField.setFocus);
		}
		
		override public function drawFocus(isFocused:Boolean):void
		{
			if(this.parentDrawsFocus)
			{
				IFocusManagerComponent(parent).drawFocus(isFocused);
				return;
			}
			
			super.drawFocus(isFocused);
		}
		
		override protected function focusInHandler(event:FocusEvent):void
		{
			if(event.target == this)
			{
				var firstTextField:TextInput = textFields[0] as TextInput;
				firstTextField.setFocus();
			}
			
			if(editable && focusManager)
			{
				focusManager.showFocus();
			}
			
			super.focusInHandler(event);
		}
		
		protected function textFieldFocusInHandler(event:FocusEvent):void
		{
			var textField:TextInput = event.currentTarget as TextInput;
			textField.selectAll();
		}
		
		protected function keyDownNavigationHandler(event:KeyboardEvent):void
		{
			var textField:TextInput = event.currentTarget as TextInput;
			switch(event.keyCode)
			{
				case Keyboard.RIGHT:
					if (textField.selectionActivePosition == textField.text.length)
					{
						focusNextTextField(textField);
					}
					break;
				case Keyboard.LEFT:
				case Keyboard.BACKSPACE:
					if(textField.selectionAnchorPosition == 0)
					{
						focusPreviousTextField(textField);
					}
					break;
				case Keyboard.ENTER:
					dispatchEvent(new FlexEvent(FlexEvent.ENTER));
					break;
			}
		}
		
		protected function textFieldChangeHandler(event:Event):void
		{
			event.stopPropagation();
		}
	}
}