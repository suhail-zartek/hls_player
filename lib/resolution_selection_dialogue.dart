import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ResolutionSelectionDialogue extends StatefulWidget {
  List<String> listResolution;
  List<String> listResolutionFileName;
  String currentSelectedresolution;

  ResolutionSelectionDialogue(
      {this.listResolution,
      this.listResolutionFileName,
      this.currentSelectedresolution});
  @override
  _ResolutionSelectionDialogueState createState() =>
      _ResolutionSelectionDialogueState(
          listResolution: listResolution,
          listResolutionFileName: listResolutionFileName,
          currentSelectedresolution: currentSelectedresolution);
}

class _ResolutionSelectionDialogueState
    extends State<ResolutionSelectionDialogue> {
  List<String> listResolution;
  List<String> listResolutionFileName;
  String currentSelectedresolution, _currentSelectedResolutionFile;
  Future<SharedPreferences> sharedPreferences = SharedPreferences.getInstance();
  _ResolutionSelectionDialogueState(
      {this.listResolution,
      this.listResolutionFileName,
      this.currentSelectedresolution});

  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    sharedPreferences.then((SharedPreferences prefs) {
      _currentSelectedResolutionFile = prefs.getString('RESOLUTIONFILE') ?? '';
    });
    if (currentSelectedresolution == null) {
      currentSelectedresolution = listResolution[0];
    }
  }

  @override
  Widget build(BuildContext context) {
    sharedPreferences.then((SharedPreferences prefs) {
      _currentSelectedResolutionFile = prefs.getString('RESOLUTIONFILE') ?? '';
    });
    if (currentSelectedresolution == null) {
      currentSelectedresolution = listResolution[0];
    }
    return AlertDialog(
      title: Text(
        'Select Quality',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
        ),
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(
          Radius.circular(25.0),
        ),
      ),
      elevation: 5.0,
      content: Container(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 5.0, vertical: 10.0),
              child: InputDecorator(
                decoration: InputDecoration(
                  contentPadding: EdgeInsets.all(15),
                  labelText: 'Select Quality',
                  labelStyle: TextStyle(
                    color: Colors.black,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15.0),
                  ),
                ),
                isEmpty: currentSelectedresolution == null,
                child: DropdownButton<String>(
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 16.0,
                    fontWeight: FontWeight.w400,
                  ),
                  underline: SizedBox(
                    height: 0,
                  ),
                  isExpanded: true,
                  isDense: true,
                  items: listResolution.map((String e) {
                    return DropdownMenuItem<String>(
                      child: Text(e),
                      value: e,
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      currentSelectedresolution = value;
                    });
                  },
                  value: currentSelectedresolution,
                ),
              ),
            ),
            SizedBox(
              height: 10.0,
            ),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 5.0, vertical: 10.0),
              child: RaisedButton(
                padding: EdgeInsets.all(14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30.0),
                ),
                color: Colors.deepOrange.shade400,
                onPressed: () {
                  setState(() {
                    if (currentSelectedresolution != null) {
                      int index =
                          listResolution.indexOf(currentSelectedresolution);
                      _currentSelectedResolutionFile =
                          listResolutionFileName[index];

                      sharedPreferences.then((SharedPreferences prefs) {
                        prefs.setString(
                            'RESOLUTIONFILE', _currentSelectedResolutionFile);
                        prefs.setString(
                            'RESOLUTION', currentSelectedresolution);
                      });

                      Navigator.of(context).pop(_currentSelectedResolutionFile);
                    }
                  });
                },
                child: Text(
                  'Download',
                  style: TextStyle(
                    fontSize: 18.0,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      actions: <Widget>[
        FlatButton(
          child: Text(
            'Cancel',
            style: TextStyle(color: Colors.deepOrange, fontSize: 17.0),
          ),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ],
    );
  }
}
