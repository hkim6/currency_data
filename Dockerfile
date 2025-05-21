FROM public.ecr.aws/lambda/python:3.12

RUN python -m pip install --upgrade pip

COPY ./currency_data_exercise/ .
COPY ./queries/ .
COPY ./requirements.txt .

COPY requirements.txt .
RUN pip install -r requirements.txt

CMD ["app.lambda_handler"]