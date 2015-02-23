package
{
	import com.bit101.components.PushButton;
	import com.bit101.components.TextArea;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.events.ProgressEvent;
	import flash.events.ServerSocketConnectEvent;
	import flash.filesystem.File;
	import flash.filesystem.FileMode;
	import flash.filesystem.FileStream;
	import flash.net.ServerSocket;
	import flash.net.Socket;
	import flash.utils.ByteArray;
	import jp.mztm.umhr.logging.Log;
	/**
	 * 参考
	 * http://help.adobe.com/ja_JP/FlashPlatform/reference/actionscript/3/flash/net/ServerSocket.html#includeExamplesSummary
	 * ...
	 * @author umhr
	 */
    public class Canvas extends Sprite
    {
        private var serverSocket:ServerSocket = new ServerSocket();
		private var _ipPort:TextArea;
        public function Canvas()
        {
            setupUI();
        }

        private function setupUI():void
        {
			_ipPort = new TextArea(this, 10, 10, "127.0.0.1:80");
			_ipPort.height = 22;
			_ipPort.autoHideScrollBar = true;
			new PushButton(this, 310, 10, "Bind", onBind);
			addChild(new Log(10, 40, 780, 560));
        }
        
        private function onBind( event:Event ):void
        {
            if ( serverSocket.bound ) { return };
			
			var ip:String = _ipPort.text.split(":")[0];
			var port:int = parseInt(_ipPort.text.split(":")[1]);
            serverSocket.bind( port, ip );
            serverSocket.addEventListener( ServerSocketConnectEvent.CONNECT, onConnect );
            serverSocket.listen();
            Log.trace( "Bound to: " + serverSocket.localAddress + ":" + serverSocket.localPort);
        }
		
        private function onConnect( event:ServerSocketConnectEvent ):void
        {
            var socket:Socket = event.socket;
            socket.addEventListener( ProgressEvent.SOCKET_DATA, onClientSocketData2 );
			socket.addEventListener(IOErrorEvent.IO_ERROR, onError);
            Log.trace( "Connection from " + socket.remoteAddress + ":" + socket.remotePort);
        }
		
		private function onError(e:Event):void 
		{
			trace(e.type);
		}
        
        private function onClientSocketData2( event:ProgressEvent ):void
        {
			try
                {
                    var bytes:ByteArray = new ByteArray();
					var socket:Socket = event.target as Socket;
                    socket.readBytes(bytes);
                    
					var requestData:RequestData = new RequestData(bytes);
					
					// GETでクエリーがあれば、ここから取り出せる。Object型
					if (requestData.queryList) {
						Log.dump(requestData.queryList);
					}
					
					// POSTでデータがあれば、ここから取り出せる。Object型
					if(requestData.postList){
						Log.dump(requestData.postList);
					}
					
					// htmlや画像ファイルなどを返す際の処理。
                    var filePath:String = File.applicationDirectory.nativePath + "/html";
					filePath += requestData.path;
                    var file:File = File.applicationStorageDirectory.resolvePath(filePath);
					if (file.isDirectory) {
						// ディレクトリだった場合、/をつけて移動させる。
						var location:String = "http://" + requestData.host + requestData.path + "/";
						socket.writeBytes(new ResponceData(301).setLocation(location).toByteArray());
					}
					else if (file.exists && !file.isDirectory)
                    {
						// ファイルが存在し、ディレクトリでない場合
						//　ファイルを開いて、書き込み、返す。
						var stream:FileStream = new FileStream();
						stream.open( file, FileMode.READ );
						var content:ByteArray = new ByteArray();
						stream.readBytes(content);
						stream.close();
						socket.writeBytes(new ResponceData(200).setByteArray(content).toByteArray(requestData.extention));
                    }
                    else
                    {
						socket.writeBytes(new ResponceData(404).toByteArray());
                    }
					
                    socket.flush();
                    socket.close();
                }
                catch (error:Error)
                {
                    //Alert.show(error.message, "Error");
                }
				
		}
		
    }
}