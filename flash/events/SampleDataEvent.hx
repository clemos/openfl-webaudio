package flash.events;

import flash.utils.ByteArray;
import js.html.audio.AudioProcessingEvent;

class SampleDataEvent extends Event {
	
	public static var SAMPLE_DATA = "sampleData";

	public var data (get_data,null) : ByteArray;

	//public var position (get_position,set_position) : Float;

	var __audioProcessingEvent : AudioProcessingEvent;

	public static function __create(e:AudioProcessingEvent){
		var _e = new SampleDataEvent( SAMPLE_DATA );
		_e.__audioProcessingEvent = e;
		return _e;
	} 

	// microphone data also comes in stereo

	function get_data(){
		if( data == null ) {
			
			var buffer = __audioProcessingEvent.inputBuffer;
			
			data = new ByteArray();
			data.length = buffer.length * buffer.numberOfChannels * 4;

			var channels = [];
			for( i in 0...buffer.numberOfChannels ){
				channels[i] = buffer.getChannelData( i );
			}

			for( i in 0...buffer.length ){
				for( c in channels ){
					data.writeFloat( c[i] );
				}
			}

			data.position = 0;

		}
		
		return data;

	}

}