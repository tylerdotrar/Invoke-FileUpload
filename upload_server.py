import os, flask, argparse
from flask import request
from werkzeug.utils import secure_filename

app = flask.Flask(__name__, static_url_path='')

app.config['UPLOAD_PATH'] = './uploads'
app.config['UPLOAD_EXTENSIONS'] = ['.jpg','.png','.pdf','.txt','.zip']

# FILE UPLOAD
@app.route('/upload', methods=['GET','POST'])
def upload_file():
    if request.method == 'POST':
        uploaded_file = request.files['TYLER.RAR']
        file_name = secure_filename(uploaded_file.filename)
        if file_name != '':
            file_ext = os.path.splitext(file_name)[1]
            if file_ext not in app.config['UPLOAD_EXTENSIONS']:
                return 'FILETYPE NOT ALLOWED'
            uploaded_file.save(os.path.join(app.config['UPLOAD_PATH'], file_name))
            return 'SUCCESSFUL UPLOAD'
        return 'FILENAME NULL'
    return 'UPLOAD ONLY'

# PARAMETERS
if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('--ip', default='0.0.0.0')
    parser.add_argument('--port', default=54321, type=int)
    parser.add_argument('--debug', action='store_true')
    parser.add_argument('--ssl', action='store_const', const='adhoc', default=None)
    args = parser.parse_args()

    app.run(host=args.ip, port=args.port, ssl_context=args.ssl, debug=args.debug)
