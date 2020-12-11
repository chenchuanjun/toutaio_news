import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:convert';
import 'dart:io';
List<ChannelList> _channelList;
NewsData _newsData;
String defaultUrl = "http://v.juhe.cn/toutiao/index?";
String key = "key=b5ce22e4e3c76da1f726817f88f72cba";
String type = "type=";
String url;
ChannelList currentChannel;

//可能用到的异步操作库
void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    _channelList = new List();
    _channelList.add(new ChannelList("top", "头条"));
    _channelList.add(new ChannelList("shehui", "社会"));
    _channelList.add(new ChannelList("guonei", "国内"));
    _channelList.add(new ChannelList("guoji", "国际"));
    _channelList.add(new ChannelList("yule", "娱乐"));
    _channelList.add(new ChannelList("tiyu", "体育"));
    _channelList.add(new ChannelList("junshi", "军事"));
    _channelList.add(new ChannelList("keji", "科技"));
    _channelList.add(new ChannelList("caijing", "财经"));
    _channelList.add(new ChannelList("shishang", "时尚"));
    currentChannel = _channelList[0];
    return MaterialApp(
        title: '头条新闻',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        home: NewsList(title: "头条新闻")
    );
  }
}

class NewsList extends StatefulWidget {
  NewsList({Key key, this.title}) : super(key:key);
  final String title;
  @override
  _NewsListState createState() => _NewsListState();
}
// DataItem类
class DataItem {
  String uniquekey;
  String title;
  String date;
  String category;
  String author_name;
  String url;
  String thumbnail_pic_s;
  String thumbnail_pic_s02;
  String thumbnail_pic_s03;
  DataItem(
      this.uniquekey,
      this.title,
      this.date,
      this.category,
      this.author_name,
      this.url,
      this.thumbnail_pic_s,
      this.thumbnail_pic_s02,
      this.thumbnail_pic_s03
      );
}
// Data类
class Data {
  List<DataItem> dataItems;
  Data.fromJson(List items) {
    dataItems = new List();
    for (var i = 0; i < items.length; i++) {
      DataItem dataItem = new DataItem(
          items[i]['uniquekey'],
          items[i]['title'],
          items[i]['date'],
          items[i]['category'],
          items[i]['author_name'],
          items[i]['url'],
          items[i]['thumbnail_pic_s'],
          items[i]['thumbnail_pic_s02'],
          items[i]['thumbnail_pic_s03']
      );
      dataItems.add(dataItem);
    }
  }
}
// Result类
class Result {
  String stat;
  Data data;
  Result.fromJson(Map<String, dynamic> jsonStr) {
    this.stat =  jsonStr['stat'];
    this.data = Data.fromJson(jsonStr['data']);
  }
}

// NewsData类
class NewsData {
  String reason;
  Result result;
  int error_code;
  NewsData(this.reason, this.result, this.error_code);
  NewsData.fromJson(Map<String, dynamic> jsonStr) {
    this.reason = jsonStr['reason'];
    this.error_code = jsonStr['error_code'];
    this.result = Result.fromJson(jsonStr['result']);
  }
}
// ChannelList 类
class ChannelList {
  String name;
  String type;
  ChannelList(this.type,this.name);
}
class _NewsListState extends State<NewsList> with SingleTickerProviderStateMixin {
  bool isLoading = false;
  List<Widget> listItems;
  // 构建侧边栏头部
  Widget buidDrawerHeader() {
    return Container(
        child: Text(
          "频道列表",
          style: TextStyle(color: Colors.white, fontSize: 30),
          textAlign: TextAlign.end,
        ),
        height: 100,
        color: Colors.blue,
        padding: EdgeInsets.all(5),
        alignment: Alignment.bottomRight
    );
  }
  // 构建侧边栏元素
  List<Widget> buildDrawerItems(List<ChannelList> _channelList) {
    List<Widget> widgets = new List();
    widgets.add(buidDrawerHeader());
    for( int i = 0; i < _channelList.length; i++) {
      widgets.add(Container(
          child: InkWell(
            child: Text(
              _channelList[i].name,
              style: TextStyle(color: Colors.blue, fontSize: 25),
              textAlign: TextAlign.center,
            ),
            onTap: () {
              currentChannel = _channelList[i];
              refresh();
            },
          ),
          padding: EdgeInsets.all(10)
      ));
    }
    return widgets;
  }
  // 刷新数据
  refresh() async {
    url = "$defaultUrl$type${currentChannel.type}&$key";
    if (!isLoading) {
      isLoading = true;
      try {
        HttpClient httpClient = new HttpClient();
        HttpClientRequest request = await httpClient.getUrl(Uri.parse(url));
        HttpClientResponse response = await request.close();
        String responseContent = await response.transform(utf8.decoder).join();
        _newsData = NewsData.fromJson(json.decode(responseContent));
        listItems = ListBuilder.genWidgetsFromJson(_newsData);
        print(_newsData);
        httpClient.close();
      } catch (e) {
        debugPrint("请求失败:$e");
      } finally {
        setState(() {
          isLoading = false;
        });
      }
    } else {
      debugPrint('正在刷新');
    }
  }
  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
          child: listItems != null ? ListView(
            children: listItems,
          ) : Text('请点击刷新按钮')
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: buildDrawerItems(_channelList),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: refresh,
        tooltip: '刷新',
        child: Icon(Icons.refresh),
      ),
    );
  }
}

class ListBuilder {
  static List<Widget> genWidgetsFromJson(NewsData newsData) {
    List<Widget> returnData = new List();
    List<DataItem> dataItems = newsData.result.data.dataItems;
    for (var i = 0; i < dataItems.length; i++) {
      returnData.add(ListItem.genSingleItem(dataItems[i]));
    }
    return returnData;
  }
}

class ListItem {
  static Widget genSingleItem(DataItem dataItem) {
    String uniquekey = dataItem.uniquekey;
    String title = dataItem.title;
    String date = dataItem.date;
    String category = dataItem.category;
    String author_name = dataItem.author_name;
    String url = dataItem.url;
    String thumbnail_pic_s = dataItem.thumbnail_pic_s;
    String thumbnail_pic_s02 = dataItem.thumbnail_pic_s02;
    String thumbnail_pic_s03 = dataItem.thumbnail_pic_s03;
    return Container(
      padding: EdgeInsets.all(5.0),
      child: InkWell(
        onTap: () {
          openDetail(url);
        },
        child: Row(
          children: <Widget>[
            Image(
              alignment: Alignment.centerLeft,
              width: 100,
              height: 100,
              image: new NetworkImage(thumbnail_pic_s),
            ),
            Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: <Widget>[
                    Container(
                      padding: EdgeInsets.all(3.0),
                      child: Text(date),
                      alignment: Alignment.topLeft,
                    ),
                    Container(
                      padding: EdgeInsets.all(3.0),
                      child: Text(
                        title,
                        softWrap: false,
                        overflow: TextOverflow.ellipsis,
                      ),
                      alignment: Alignment.centerLeft,
                    ),
                    Container(
                      padding: EdgeInsets.all(3.0),
                      child: Text(author_name),
                      alignment: Alignment.bottomLeft,
                    )
                  ],
                )
            )
          ],
        ),
      ),
    );
  }
  static void openDetail(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }
}











