FROM public.ecr.aws/lambda/python:3.12

RUN python -m pip install --upgrade pip

COPY ./de_exercise_prt/ .
COPY ./queries/ .
COPY ./requirements.txt .

COPY requirements.txt .
RUN pip install -r requirements.txt

CMD ["app.lambda_handler"]