import 'package:flutter/material.dart';
import 'package:flutter_bloc_pattern/flutter_bloc_pattern.dart';
import 'package:flutter_disposebag/flutter_disposebag.dart';

import '../../utils/delay.dart';
import '../../utils/snackbar.dart';
import '../widgets/password_text_field.dart';
import 'register_bloc.dart';
import 'register_state.dart';

class RegisterPage extends StatefulWidget {
  static const routeName = '/register';

  @override
  _RegisterPageState createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage>
    with SingleTickerProviderStateMixin {
  DisposeBag disposeBag;

  AnimationController buttonController;
  Animation<double> buttonSqueezeAnimation;

  FocusNode passwordFocusNode;
  TextEditingController emailController;

  @override
  void initState() {
    super.initState();

    buttonController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    buttonSqueezeAnimation = Tween(
      begin: 200.0,
      end: 70.0,
    ).animate(
      CurvedAnimation(
        parent: buttonController,
        curve: Interval(
          0.0,
          0.250,
        ),
      ),
    );

    passwordFocusNode = FocusNode();
    emailController = TextEditingController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    disposeBag ??= () {
      final loginBloc = BlocProvider.of<RegisterBloc>(context);
      return DisposeBag([
        loginBloc.message$.listen(handleMessage),
        loginBloc.isLoading$.listen((isLoading) {
          if (isLoading) {
            buttonController
              ..reset()
              ..forward();
          } else {
            buttonController.reverse();
          }
        })
      ]);
    }();
  }

  @override
  void dispose() {
    buttonController.dispose();
    disposeBag.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loginBloc = BlocProvider.of<RegisterBloc>(context);

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Container(
              constraints: BoxConstraints.expand(),
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/images/register_bg.png'),
                  fit: BoxFit.cover,
                  colorFilter: ColorFilter.mode(
                    Colors.black.withOpacity(0.6),
                    BlendMode.darken,
                  ),
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: Container(
              constraints: BoxConstraints.expand(),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: <Color>[
                    const Color(0xffB881F9).withOpacity(0.58),
                    const Color(0xff545AE9).withOpacity(0.58),
                  ],
                  begin: AlignmentDirectional.topEnd,
                  end: AlignmentDirectional.bottomStart,
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: Center(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Image.asset('assets/images/enjoy.png'),
                    const SizedBox(height: 24),
                    Text(
                      'Create your Account',
                      style: Theme.of(context).textTheme.headline6.copyWith(
                            fontSize: 18,
                            color: Colors.white,
                          ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: emailTextField(loginBloc),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: passwordTextField(loginBloc),
                    ),
                    const SizedBox(height: 32.0),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: registerButton(loginBloc),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void handleMessage(message) async {
    if (message is RegisterSuccessMessage) {
      context.showSnackBar(
          'Register successfully. Please check your email inbox to verify this account.');
      await delay(1000);
      await Navigator.of(context).pop(message.email);
    }
    if (message is RegisterErrorMessage) {
      context.showSnackBar(message.message);
    }
    if (message is InvalidInformationMessage) {
      context.showSnackBar('Invalid information');
    }
  }

  Widget emailTextField(RegisterBloc bloc) {
    return StreamBuilder<String>(
      stream: bloc.emailError$,
      builder: (context, snapshot) {
        return TextField(
          controller: emailController,
          autocorrect: true,
          decoration: InputDecoration(
            prefixIcon: Padding(
              padding: const EdgeInsetsDirectional.only(end: 8.0),
              child: Icon(
                Icons.email,
                color: Colors.white,
              ),
            ),
            labelText: 'Email',
            errorText: snapshot.data,
            labelStyle: TextStyle(color: Colors.white),
            fillColor: Colors.white,
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.white),
            ),
          ),
          keyboardType: TextInputType.emailAddress,
          maxLines: 1,
          style: TextStyle(fontSize: 16.0, color: Colors.white),
          onChanged: bloc.emailChanged,
          textInputAction: TextInputAction.next,
          autofocus: true,
          onSubmitted: (_) {
            FocusScope.of(context).requestFocus(passwordFocusNode);
          },
        );
      },
    );
  }

  Widget passwordTextField(RegisterBloc bloc) {
    return StreamBuilder<String>(
      stream: bloc.passwordError$,
      builder: (context, snapshot) {
        return PasswordTextField(
          errorText: snapshot.data,
          onChanged: bloc.passwordChanged,
          labelText: 'Password',
          textInputAction: TextInputAction.done,
          onSubmitted: () {
            FocusScope.of(context).requestFocus(FocusNode());
          },
          focusNode: passwordFocusNode,
        );
      },
    );
  }

  Widget registerButton(RegisterBloc bloc) {
    return AnimatedBuilder(
      animation: buttonSqueezeAnimation,
      child: MaterialButton(
        onPressed: () {
          FocusScope.of(context).requestFocus(FocusNode());
          bloc.submit();
        },
        color: Theme.of(context).backgroundColor,
        child: Text(
          'REGISTER',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16.0,
          ),
        ),
        splashColor: Theme.of(context).accentColor,
      ),
      builder: (context, child) {
        final value = buttonSqueezeAnimation.value;

        return Container(
          width: value,
          height: 60.0,
          child: Material(
            elevation: 5.0,
            clipBehavior: Clip.antiAlias,
            shadowColor: Theme.of(context).accentColor,
            borderRadius: BorderRadius.circular(30.0),
            child: value > 75.0
                ? child
                : Center(
                    child: CircularProgressIndicator(strokeWidth: 2.0),
                  ),
          ),
        );
      },
    );
  }
}
