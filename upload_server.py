import os
import flask
from flask import send_from_directory, request
from werkzeug.utils import secure_filename

app = flask.Flask(__name__, static_url_path='')

app.config['UPLOAD_PATH'] = './uploads'
app.config['UPLOAD_EXTENSIONS'] = ['.jpg','.png','.pdf','.txt','.zip']

# FILE UPLOADING
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

if __name__ == '__main__':
    app.run(host='0.0.0.0',port=54321,ssl_context='adhoc',debug=False)
