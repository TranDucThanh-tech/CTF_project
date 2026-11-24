FROM python:3.12-slim
RUN pip install --no-cache-dir pycryptodome sympy gmpy2

WORKDIR /work
CMD ["bash"]
