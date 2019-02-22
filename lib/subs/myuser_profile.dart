import 'package:flutter/material.dart';
import 'package:myusica/helpers/myuser.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:myusica/subs/register.dart';

class MyuserProfile extends StatefulWidget {
  final Myuser myuser;
  final String imageUrl;
  final bool isFromMyAccount; // boolean showing if user has come to this page from MyAccount page 
  MyuserProfile({this.myuser, this.imageUrl, this.isFromMyAccount});

  @override
  MyuserProfileState createState() => new MyuserProfileState();  
}

class MyuserProfileState extends State<MyuserProfile> {
  String ppString;
  bool isFromMyAccount;
  List<String> days = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];
  @override
  void initState() {
    super.initState();
    setState(() {
     ppString = widget.imageUrl; 
     isFromMyAccount = widget.isFromMyAccount;
    });
  }

  /// navigate to Register page
  /// [isFromProfile] set to true to show register code that this is going to be a profile update,
  /// not an initial Myuser registration
  _navigateToRegister() {
    Navigator.push(
      context, 
      MaterialPageRoute(settings: RouteSettings(), 
        builder: (context) => Register(myuser: widget.myuser, isFromProfile: true,))
    );
  }

  // create availability tile item from availability map
  List<TextSpan> _createAvailabilityTile() {
    var keyList = widget.myuser.availability.keys.toList()..sort(
      (a, b) => days.indexOf(a).compareTo(days.indexOf(b)));
    List<TextSpan> textSpanList = new List<TextSpan>();
  
    // create a new line to separate days if this isn't the first item
    keyList.forEach((key) {
      if (keyList.indexOf(key) != 0) {
        textSpanList.add(
          new TextSpan(text: "\n"),
        );
      }

      // add day item
      textSpanList.add(
        new TextSpan(text: key, style: new TextStyle(fontWeight: FontWeight.bold)),
      );

      textSpanList.add(new TextSpan(text: ": ("));
      int i = 0;
        widget.myuser.availability[key].forEach((k, v) {
          if (i < widget.myuser.availability[key].keys.length-1)
            textSpanList.add(new TextSpan(text: k + ", "));
          else textSpanList.add(new TextSpan(text: k));
          i += 1;
        });

      textSpanList.add(new TextSpan(text: ")"));
    });
    return textSpanList;
  }



  @override
  Widget build(BuildContext context) {
    String specs = widget.myuser.specializations.toString();
    return Scaffold(
      appBar: AppBar(
        title: Text("Profile"),
        actions: <Widget>[
          !isFromMyAccount ? FlatButton(
            child: Text("Chat", style: TextStyle(fontSize: 17.0),),
            onPressed: null,
          ) : Container(height: 0.0, width: 0.0,),
          isFromMyAccount ? IconButton(
            icon: Icon(
              Icons.edit,
            ),
            tooltip: 'Edit profile',
            onPressed: _navigateToRegister,
          ) : null,
        ]
      ),
      body: Scrollbar(
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: 5.0
            ),
            child: Column(
              children: <Widget>[
                SizedBox(
                  // height: 210.0,
                  child: Card(
                    child: Column(
                      children: [
                        ListTile(
                          title: Text(widget.myuser.name,
                              style: TextStyle(fontWeight: FontWeight.w500)),
                          subtitle: Text(widget.myuser.city + ", " + widget.myuser.state),
                          // if user has no profile picture, just use a person icon
                          // leading: ppString == null ? CircleAvatar(
                          //     radius: 30.0,
                          //     child: Text(widget.myuser.name.substring(0, 1)),
                          //   ) : 
                            leading: CircleAvatar(
                              radius: 30.0,
                              backgroundImage: CachedNetworkImageProvider(ppString),
                              backgroundColor: Colors.transparent,
                            ),
                        ),
                        Divider(),
                        ListTile(
                          title: Text(widget.myuser.phone,
                              style: TextStyle(fontWeight: FontWeight.w500)),
                          leading: Icon(
                            Icons.contact_phone,
                            color: Colors.blue[500],
                          ),
                        ),
                        ListTile(
                          title: Text(widget.myuser.email),
                          leading: Icon(
                            Icons.contact_mail,
                            color: Colors.blue[500],
                          ),
                        ),
                        ListTile(
                          title: Text(specs.substring(1, specs.length-1)),
                          leading: Icon(
                            Icons.work,
                            color: Colors.blue[500],
                          ),
                        ),
                        ListTile(
                          title: Text("US\$ " + widget.myuser.charge.toStringAsFixed(2)),
                          leading: Icon(
                            Icons.monetization_on,
                            color: Colors.blue[500],
                          ),
                        ),
                        ListTile(
                          title: RichText(
                            text: TextSpan(
                              style: TextStyle(fontSize: 15.0),
                              children: _createAvailabilityTile()
                            ),
                          ),
                          leading: Icon(
                            Icons.access_time,
                            color: Colors.blue[500],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),  
      ) 
    );
  }
}