# dockerfile, image, container
FROM python:3.9

ADD back_end_flask.py .

RUN pip install requests flask

EXPOSE 5000
CMD ["python", "./back_end_flask.py"]