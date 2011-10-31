package com.roohoo.flex.view.components
{
	import com.roohoo.flex.view.components.renderers.MultiselectListItemRenderer;
	
	import flash.display.DisplayObject;
	import flash.events.Event;
	import flash.events.KeyboardEvent;
	import flash.events.MouseEvent;
	import flash.geom.Rectangle;
	
	import mx.collections.ArrayCollection;
	import mx.collections.IList;
	import mx.core.ClassFactory;
	import mx.core.FlexGlobals;
	import mx.events.FlexEvent;
	import mx.managers.PopUpManager;
	import mx.utils.StringUtil;
	
	import spark.components.Button;
	import spark.components.Group;
	import spark.components.List;
	import spark.components.TextInput;
	import spark.events.IndexChangeEvent;
	
	public class MultiSelectBox extends Group
	{
		public static const DEFAULT_PROMPT:String = '{0}: {1} selected';
		public static const DEFAULT_LABEL:String = 'Items';
		
		public static const MODE_COLLAPSED:Number = 1;
		public static const MODE_EXPANDED:Number = 2;
		
		public static const DD_MAX_HEIGHT:Number = 500;
		
		[Bindable]
		[Embed('/com/roohoo/flex/theme/assets/dd.png')]
		public static var ICON_DD_SWITCHER:Class;
		
		
		/**
		 * Public editable parameters
		 */
		
		[Bindable]
		public var prompt:String = DEFAULT_PROMPT;
		
		[Bindable]
		public var label:String = 'Items';
		
		[Bindable]
		public var labelField:String = 'label';
		
		[Bindable]
		public var dataField:String = 'data';
		
		[Bindable]
		public var ddMaxHeight:Number = DD_MAX_HEIGHT;
		
		/**
		 * END Public editable parameters
		 */
		
		private var _inited:Boolean = false;
		
		private var _ddInited:Boolean = false;
		
		private var _lblData:TextInput;
		
		private var _ddSwitcher:Button
		
		[Bindable]
		private var _dd:List;
		
		[Bindable]
		private var _mode:Number = MODE_COLLAPSED;
		
		[Bindable]
		private var _dataProvider:ArrayCollection = new ArrayCollection();
		
		[Bindable]
		private var _rawValue:Array = [];
		
		public function MultiSelectBox()
		{
			super();
			
			// fill in components 
			_lblData = new TextInput();
			_lblData.top = 0;
			_lblData.right = 19;
			_lblData.bottom = 0;
			_lblData.left = 0;
			_lblData.editable = false;
			_lblData.addEventListener(MouseEvent.CLICK, switchDD);
			addElement(_lblData);
			
			_ddSwitcher = new Button();
			_ddSwitcher.setStyle('icon', ICON_DD_SWITCHER);
			_ddSwitcher.width = 20;
			_ddSwitcher.top = 0;
			_ddSwitcher.right = 0;
			_ddSwitcher.bottom = 0;
			_ddSwitcher.label = '';
			_ddSwitcher.addEventListener(MouseEvent.CLICK, switchDD);
			addElement(_ddSwitcher);
			
			_dd = new List();
			_dd.allowMultipleSelection = true;
			_dd.addEventListener(IndexChangeEvent.CHANGE, onDDChange);
			_dd.addEventListener(KeyboardEvent.KEY_DOWN, onDDKeyDown);
			_dd.itemRenderer = new ClassFactory(MultiselectListItemRenderer);
			_dd.addEventListener(FlexEvent.CREATION_COMPLETE, initDD);
			
			// on complete init user defined settings
			addEventListener(FlexEvent.CREATION_COMPLETE, initView);
		}
		
		private function updateLabel():void
		{	
			if (_rawValue && _rawValue.length > 0) {
				_lblData.text = StringUtil.substitute(prompt, label, _rawValue.length);
			} else {
				_lblData.text = label;
			}
		}
		
		private function updateDD():void
		{
			var rect:Rectangle = this.getRect(FlexGlobals.topLevelApplication as DisplayObject);
			_dd.x = rect.left - 1;
			_dd.y = rect.bottom;
			
			_dd.width = this.width;
			if (dataProvider != null) {
				_dd.height = dataProvider.length * MultiselectListItemRenderer.ELEMENT_HEIGHT;
			} else {
				_dd.height = 20;
			}
		}
		
		private function expandDD():void
		{
			updateDD();
			
			PopUpManager.addPopUp(_dd, this, false);
			FlexGlobals.topLevelApplication.addEventListener(MouseEvent.MOUSE_DOWN, dropdown_mouseOutsideHandler);
			
			_mode = MODE_EXPANDED;
		}
		
		private function collapseDD():void
		{
			PopUpManager.removePopUp(_dd);
			FlexGlobals.topLevelApplication.removeEventListener(MouseEvent.MOUSE_DOWN, dropdown_mouseOutsideHandler);
			
			_mode = MODE_COLLAPSED;
		}
		
		private function getIndexByField(field:String):int
		{
			for each (var el:* in _dataProvider) {
				if (el[dataField] == field) {
					return _dataProvider.getItemIndex(el);
				}
			}
			return -1;
		}
		
		private function applyRawValue():void
		{
			if (_ddInited && _rawValue != null) {
				
				var selectedIndices:Vector.<int> = new Vector.<int>();
				
				for each (var item:* in _rawValue) {
					
					if (item is String)
					{
						var indStr:int = getIndexByField(item);
						if (indStr >= 0) {
							selectedIndices.push(indStr);
						}
					}
					else if (item is Object)
					{
						var indObj:int = getIndexByField(item[dataField]);
						if (indObj >= 0) {
							selectedIndices.push(indObj);
						}
					}
					else
					{
						throw new Error('Unsupported rawValue data type!'); 
					}
					
				}
				
				_dd.selectedIndices = selectedIndices;
				
				_dd.callLater(function ():void {
					_dd.dispatchEvent(new IndexChangeEvent(IndexChangeEvent.CHANGE));
				});
			}
		}
		
		private function initView(event:Event):void
		{
			_inited = true;
			
			_dd.maxHeight = ddMaxHeight;
			_dd.labelField = labelField;
			_dd.dataProvider = dataProvider;
			
			// update component display text
			updateLabel();
			
		}
		
		private function initDD(event:Event):void
		{
			// on _dd creation complete - first apply raw value
			_ddInited = true;
			
			applyRawValue();			
		}
		
		private function switchDD(event:Event):void
		{
			if (_mode == MODE_COLLAPSED) {
				expandDD();
			} else {
				collapseDD();
			}
		}
		
		private function dropdown_mouseOutsideHandler(event:Event):void
		{
			if (event is MouseEvent) {
				var mouseEvent:MouseEvent = MouseEvent(event);
				if (!hitTestPoint(mouseEvent.stageX, mouseEvent.stageY, true)) {
					collapseDD();
				}
			}
		}
		
		private function onDDKeyDown(event:KeyboardEvent):void
		{
			if (event.keyCode == 13) {
				collapseDD();
			}
		}
		
		private function onDDChange(event:Event):void
		{
			var out:Array = [];
			for each (var item:* in _dd.selectedItems) {
				out.push(item[dataField]);
			}
			
			_rawValue = out;
			
			updateLabel();
		}
		
		public function get dataProvider():*
		{
			return _dataProvider;
		}
		
		public function set dataProvider(value:*):void
		{
			if (value != null) {
				
				if (value is IList)
				{
					_dataProvider = value;
				}
				else if (value is Array)
				{
					// In case of Array
					var fromArray:ArrayCollection = new ArrayCollection();
					for each (var item:* in value) {
						if (item is String)
						{
							var obj:Object = {};
							obj[labelField] = item;
							obj[dataField] = item;
							fromArray.addItem(obj);
						}
						else if (item is Object)
						{
							fromArray.addItem(item);
						}
						else
						{
							throw new Error('Unsupported type of dataProvider element!'); 
						}
					}
					_dataProvider = fromArray;
				}
			}
		}
		
		public function get rawValue():Array
		{
			return _rawValue;
		}
		
		public function set rawValue(value:Array):void
		{
			_rawValue = value;
			
			applyRawValue();
		}
	}
}