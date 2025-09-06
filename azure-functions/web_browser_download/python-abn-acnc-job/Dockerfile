# Use a lightweight base Python image
FROM python:3.10-slim

# Set the working directory
WORKDIR /app

# Copy all project files into the container
COPY . .

# Install dependencies
RUN pip install --upgrade pip && pip install -r requirements.txt

# Default command to run the main script
CMD ["python", "main.py"]
