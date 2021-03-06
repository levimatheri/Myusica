import 'package:flutter/material.dart';
import 'package:myusica/helpers/auth.dart';
import 'package:flutter/services.dart';
import 'package:myusica/helpers/dialogs.dart';

class LoginPage extends StatefulWidget {
  LoginPage({this.auth, this.onSignedIn});

  final BaseAuth auth;
  final VoidCallback onSignedIn;
  
  @override
  LoginPageState createState() => new LoginPageState();
}

enum FormMode { LOGIN, SIGNUP }

class LoginPageState extends State<LoginPage> {
  final _formKey = new GlobalKey<FormState>();

  FormMode _formMode = FormMode.LOGIN; // initialize as login
  bool _isLoading;

  bool _isIos;

  String _username;
  String _email;
  String _password;
  String _errorMessage;

  TextEditingController _emailTextController = TextEditingController();
  TextEditingController _passwordTextController = TextEditingController();
  TextEditingController _confirmPasswordTextController = TextEditingController();

  // check if form is valid before logging in or signing up
  bool _validateAndSave() {
    final form = _formKey.currentState;
    if (form.validate()) {
      form.save();
      return true;
    }
    setState(() {
     _isLoading = false; 
    });
    return false;
  }

  _validateAndSubmit() async {
    setState(() {
      _errorMessage = "";
      _isLoading = true;    
    });

    if (_validateAndSave()) {
      String userId = "";
      try {
        if (_formMode == FormMode.LOGIN) {
          userId = await widget.auth.signIn(_email, _password);
          if (userId == 'Email not verified') {
            setState(() {
             _isLoading = false; 
            });
            showAlertDialog(context, ["Okay"], "Email not verified", "Check your email to verify");
            return;
          }

          // check to see if this user is in our database. If not this is a new user, add them
          String possibleUserName = await widget.auth.getUsername(userId);
          if (possibleUserName == null) {
            await widget.auth.addNewCustomUser(_username, userId);
          }

          print('Signed in user: $userId');
        } else {
          if (_confirmPasswordTextController.text !=_passwordTextController.text) {
            setState(() {
             _isLoading = false; 
            });
            showAlertDialog(context, ["Okay"], "ERROR", "Passwords do not match");
            return;
          }
          userId = await widget.auth.signUp(_username, _email, _password);
          if (userId == 'Email verification could not be sent') {
            setState(() {
             _isLoading = false; 
            });
            showAlertDialog(context, ["Okay"], "ERROR", "Email verification could not be sent." + 
                                                        "Make sure email is valid");
            return;
          }
          // redirect to Login
          else { 
            print('Signed up user: $userId');
            showAlertDialog(context, ["Okay"], "Success!", "You have been signed in successfully. Check your email to verify");
            setState(() {
              _isLoading = false;        
            });
            _changeFormToLogin(); 
            return;
          }
        }

        setState(() {
          _isLoading = false;        
        });

        if (userId != null) widget.onSignedIn();
      } on PlatformException catch (e) {
        print('Error: $e');
        setState(() {
          _isLoading = false;
          if (_isIos) _errorMessage = e.details;
          else _errorMessage = e.message;
        });
        if (_formMode == FormMode.LOGIN)
          showAlertDialog(context, ["Okay"], "Error", _errorMessage);
        else showAlertDialog(context, ["Okay"], "Error", _errorMessage);
      }
    }
  }

  @override
  void initState() {
    _errorMessage = "";
    _isLoading = false;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    _isIos = Theme.of(context).platform == TargetPlatform.iOS;
    // prevent user from going back to home (using the system back button) after they log out using WillPopScope
    return WillPopScope(
      onWillPop: () async => false,
      child: new Scaffold(
        appBar: new AppBar(
          title: new Text("Log in"),
          automaticallyImplyLeading: false, // removes back button so that user can only use log out
        ),
        body: Stack(
          children: <Widget>[
            _showBody(),
            _showCircularProgress(),
          ],
        ),
      )
    );
  }

  Widget _showCircularProgress() {
    if (_isLoading) return Center(child: CircularProgressIndicator(),);
    return Container(height: 0.0, width: 0.0);
  }

  Widget _showLogo() {
    return new Hero(
      tag: 'hero',
      child: Padding(
        padding: EdgeInsets.fromLTRB(0.0, 5.0, 0.0, 0.0),
                                // : EdgeInsets.fromLTRB(0.0, 0.0, 0.0, 0.0),
        child: CircleAvatar(
          backgroundColor: Colors.transparent,
          radius: 50.0,
          child: Image.asset('images/Myusica logo.png'),
        ),
      ),
    );
  }

  Widget _showUsernameInput() {
    return _formMode == FormMode.SIGNUP ?  Padding(
      padding: EdgeInsets.fromLTRB(0.0, 5.0, 0.0, 10.0),
      child: new TextFormField(
        maxLines: 1,
        keyboardType: TextInputType.emailAddress,
        autofocus: false,
        decoration: new InputDecoration(
          hintText: 'Username',
          icon: new Icon(
            Icons.person,
            color: Colors.blue[200],
          ),
        ),
        validator: (value) => value.isEmpty ? 'Username cannot be empty' : null,
        onSaved: (value) => _username = value,
      ),
    ) : Container(height: 0.0, width: 0.0); 
  }

  Widget _showEmailInput() {
    return Padding(
      padding: _formMode == FormMode.LOGIN ? EdgeInsets.fromLTRB(0.0, 10.0, 0.0, 20.0) 
                                    : EdgeInsets.fromLTRB(0.0, 10.0, 0.0, 10.0),
      child: new TextFormField(
        maxLines: 1,
        keyboardType: TextInputType.emailAddress,
        autofocus: false,
        decoration: new InputDecoration(
          hintText: 'Email',
          icon: new Icon(
            Icons.mail,
            color: Colors.blue[200],
          ),
        ),
        validator: (value) => value.isEmpty ? 'Email cannot be empty' : null,
        onSaved: (value) => _email = value,
      ),
    );
  }

  Widget _showPasswordInput() {
    return Padding(
      padding: _formMode == FormMode.LOGIN ? EdgeInsets.fromLTRB(0.0, 10.0, 0.0, 20.0) 
                                  : EdgeInsets.fromLTRB(0.0, 10.0, 0.0, 10.0),
      child: new TextFormField(
        controller: _passwordTextController,
        maxLines: 1,
        obscureText: true,
        autofocus: false,
        decoration: new InputDecoration(
          hintText: 'Password',
          icon: new Icon(
            Icons.lock,
            color: Colors.blue[200],
          ),
        ),
        validator: (value) => value.isEmpty ? 'Password cannot be empty' : null,
        onSaved: (value) => _password = value,
      ),
    );
  }

  Widget _showConfirmPasswordInput() {
    return _formMode == FormMode.SIGNUP ? Padding(
      padding: const EdgeInsets.fromLTRB(0.0, 10.0, 0.0, 0.0),
      child: new TextFormField(
        controller: _confirmPasswordTextController,
        maxLines: 1,
        obscureText: true,
        autofocus: false,
        decoration: new InputDecoration(
          hintText: 'Confirm password',
          icon: new Icon(
            Icons.lock,
            color: Colors.blue[200],
          ),
        ),
        validator: (value) {
          if (value.isEmpty) 
          {
            showAlertDialog(context, ["Okay"], "Error", "Please confirm password");
            return;
          }
        }
      ),
    ) : Container();
  }

  Widget _showPrimaryButton() {
    return new Padding(
      padding: EdgeInsets.fromLTRB(0.0, 45.0, 0.0, 0.0),
      child: new MaterialButton(
        elevation: 5.0,
        minWidth: 200.0,
        height: 42.0,
        color: Colors.orange,
        child: _formMode == FormMode.LOGIN
              ? new Text('Login',
                    style: new TextStyle(fontSize: 20.0, color: Colors.white))
              : new Text('Create account',
                    style: new TextStyle(fontSize: 20.0, color: Colors.white)),
        onPressed: _validateAndSubmit,
      ),
    );
  }

  Widget _showSecondaryButton() {
    return new FlatButton(
      child: _formMode == FormMode.LOGIN
              ? new Text('Create an account',
                style: new TextStyle(fontSize: 16.0, 
                fontWeight: FontWeight.w300))
              : new Text('Have an account? Sign in',
                style: new TextStyle(fontSize: 18.0, 
                fontWeight: FontWeight.w300)),
      onPressed: _formMode == FormMode.LOGIN
                  ? _changeFormToSignUp
                  : _changeFormToLogin,
    );
  }

  Widget _showForgotPassword() {
    return new FlatButton(
      child: Text("Forgot password?", style: TextStyle(fontSize: 16.0),),
      onPressed: _resetPassword,
    );
  }

  void _resetPassword() async {
    // we need email input to know where to send reset instructions
    if (_emailTextController.text == null) {
      showAlertDialog(context, ["Okay"], "Error", "Input email above first, then click on \'Forgot Password?\'");
      return;
    }
    String toSendEmail = _email;
    try {
      setState(() {
       _isLoading = true; 
      });
      await widget.auth.resetPassword(toSendEmail);
    } catch (e) {
      setState(() {
       _isLoading = false; 
      });
      showAlertDialog(context, ["Okay"], "Error" , "An error occurred while resetting password");
      return;
    }
    
    setState(() {
      _isLoading = false; 
    });
    showAlertDialog(context, ["Okay"], "Info", "An email containing instructions on how to reset your password has been sent to $toSendEmail");
  }


  void _changeFormToSignUp() {
    _formKey.currentState.reset();
    _errorMessage = "";
    print("Changing to sign up");
    setState(() {
      _emailTextController.text = "";
      _passwordTextController.text = "";
      _confirmPasswordTextController.text = "";
      _formMode = FormMode.SIGNUP;
    });
  }

  void _changeFormToLogin() {
    _formKey.currentState.reset();
    _errorMessage = "";
    print("Changing to login");
    setState(() {
      _emailTextController.text = "";
      _passwordTextController.text = "";
      _formMode = FormMode.LOGIN;
    });
  }

  Widget _showErrorMessage() {
    if (_errorMessage != null) {
      return new Text(
        _errorMessage,
        style: TextStyle(
          fontSize: 13.0,
          color: Colors.red,
          height: 1.0,
          fontWeight: FontWeight.w300
        ),
      );
    } else {
      return new Container(height: 0.0,);
    }
  }

  Widget _showBody() {
    return new Container(
      padding: EdgeInsets.all(16.0),
      child: new Form(
        key: _formKey,
        child: new ListView(
          shrinkWrap: true,
          children: <Widget>[
            _showLogo(),
            _showUsernameInput(),
            _showEmailInput(),
            _showPasswordInput(),
            _showConfirmPasswordInput(),
            _showPrimaryButton(),
            _showSecondaryButton(),
            _formMode == FormMode.LOGIN ? _showForgotPassword() : Container(height: 0.0, width: 0.0,),
            //_showErrorMessage(),
          ],
        ),
      ),
    );
  }
}