import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import '../config/httpHeaders.dart';
import 'articleDetail.dart';

class HomePage extends StatefulWidget {
  @override
  HomePageState createState() => new HomePageState();
}

class HomePageState extends State<HomePage> {
//  获取分类
  Future getCategories() async {
    final response = await http.get(
        'https://gold-tag-ms.juejin.im/v1/categories',
        headers: httpHeaders);
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load categories');
    }
  }

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return FutureBuilder(
      future: getCategories(),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          var tabList = snapshot.data['d']['categoryList'];
          return new CreatePage(
            tabList: tabList,
          );
        } else if (snapshot.hasError) {
          return Text("error1>>>>>>>>>>>>>>>:${snapshot.error}");
        }
        return new Container(
          color: new Color.fromRGBO(244, 245, 245, 1.0),
        );
      },
    );
  }
}

//创建页面
class CreatePage extends StatefulWidget {
  final List tabList;

  @override
  CreatePage({Key key, this.tabList}) : super(key: key);

  CreatePageState createState() => new CreatePageState();
}

class CreatePageState extends State<CreatePage>
    with SingleTickerProviderStateMixin {
  @override
  Widget build(BuildContext context) {
    //TODO: implement build
    return new DefaultTabController(
        length: widget.tabList.length,
        child: new Scaffold(
          appBar: new AppBar(
            backgroundColor: new Color.fromRGBO(244, 245, 245, 1.0),
            automaticallyImplyLeading: false,
            titleSpacing: 0.0,
            title: new TabBar(
                indicatorSize: TabBarIndicatorSize.label,
                isScrollable: true,
                labelColor: Colors.blue,
                unselectedLabelColor: Colors.grey,
                tabs: widget.tabList.map((tab) {
                  return new Tab(
                    text: tab['name'],
                  );
                }).toList()),
            actions: <Widget>[
              new IconButton(
                  icon: new Icon(
                    Icons.add,
                    color: Colors.blue,
                  ),
                  onPressed: () {
                    Navigator.pushNamed(context, '/shareArticle');
                  })
            ],
          ),
          body: new TabBarView(
              children: widget.tabList.map((cate) {
                return ArticleLists(
                  categories: cate,
                );
              }).toList()),
        ));
  }
}

class ArticleLists extends StatefulWidget {
  final Map categories;

  @override
  ArticleLists({Key key, this.categories}) : super(key: key);

  ArticleListsState createState() => new ArticleListsState();
}

class ArticleListsState extends State<ArticleLists> {
  List articleList;

  Future getArticles({int limit = 20, String category}) async {
    final String url =
        'https://timeline-merger-ms.juejin.im/v1/get_entry_by_rank?src=${httpHeaders['X-Juejin-Src']}&uid=${httpHeaders['X-Juejin-Uid']}&device_id=${httpHeaders['X-Juejin-Client']}&token=${httpHeaders['X-Juejin-Token']}&limit=$limit&category=$category';
    final response = await http.get(Uri.encodeFull(url));
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load post');
    }
  }

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return new FutureBuilder(
        future: getArticles(category: widget.categories['id']),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            articleList = snapshot.data['d']['entrylist'];
            print(articleList);
            return new ListView.builder(
                itemCount: articleList.length,
                itemBuilder: (context, index) {
                  var item = articleList[index];
                  return createItem(item);
                });
          } else if (snapshot.hasError) {
            return new Center(
              child: new Text("error2>>>>>>>>>>>>>>>:${snapshot.error}"),
            );
          }
          return new CupertinoActivityIndicator();
        });
  }

//单个文章
  Widget createItem(articleInfo) {
    var objectId = articleInfo['originalUrl']
        .substring(articleInfo['originalUrl'].lastIndexOf('/') + 1);
    var tags = articleInfo['tags'];
    return new Container(
      margin: new EdgeInsets.only(bottom: 10.0),
      padding: new EdgeInsets.only(top: 10.0, bottom: 10.0),
      child: new FlatButton(
        padding: new EdgeInsets.all(0.0),
        onPressed: () {
          Navigator.push(
              context,
              new CupertinoPageRoute(
                  builder: (context) => ArticleDetail(
                    objectId: objectId,
                    articleInfo: articleInfo,
                  )));
        },
        child: new Column(
          children: <Widget>[
            new Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                new FlatButton(
                    onPressed: null,
                    child: new Row(
                      children: <Widget>[
                        new CircleAvatar(
                          backgroundImage: new NetworkImage(
                              articleInfo['user']['avatarLarge']),
                        ),
                        new Padding(padding: new EdgeInsets.only(right: 5.0)),
                        new Text(
                          articleInfo['user']['username'],
                          style: new TextStyle(color: Colors.black),
                        )
                      ],
                    )),
                tags.isNotEmpty
                    ? (tags.length >= 2
                    ? new Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: <Widget>[
                    new FlatButton(
                        onPressed: null,
                        child: new Text(
                          tags[0]['title'].toString(),
                          style: new TextStyle(fontSize: 14.0),
                        )),
                    new Text('/'),
                    new FlatButton(
                        onPressed: null,
                        child: new Text(
                          tags[1]['title'].toString(),
                          style: new TextStyle(fontSize: 14.0),
                        ))
                  ],
                )
                    : new FlatButton(
                    onPressed: null,
                    child: new Text(
                      tags[0]['title'].toString(),
                      style: new TextStyle(fontSize: 14.0),
                    )))
                    : new Container(
                  width: 0.0,
                  height: 0.0,
                )
              ],
            ),
            new ListTile(
              title: new Text(articleInfo['title']),
              subtitle: new Text(
                articleInfo['summaryInfo'],
                maxLines: 2,
              ),
            ),
            new Row(
              children: <Widget>[
                new FlatButton(
                    onPressed: null,
                    child: new Row(
                      children: <Widget>[
                        new Icon(Icons.favorite),
                        new Padding(padding: new EdgeInsets.only(right: 5.0)),
                        new Text(articleInfo['collectionCount'].toString())
                      ],
                    )),
                new FlatButton(
                    onPressed: null,
                    child: new Row(
                      children: <Widget>[
                        new Icon(Icons.message),
                        new Padding(padding: new EdgeInsets.only(right: 5.0)),
                        new Text(articleInfo['commentsCount'].toString())
                      ],
                    ))
              ],
            )
          ],
        ),
      ),
      color: Colors.white,
    );
  }
}