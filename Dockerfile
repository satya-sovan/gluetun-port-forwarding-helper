# Use Python 3.11 Alpine image for smaller size
FROM python:3.11-alpine

# Set working directory
WORKDIR /app

# Install dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy application files
COPY update-port-helper.py .

# Create non-root user for security
RUN addgroup -g 1000 appuser && \
    adduser -D -u 1000 -G appuser appuser

# Switch to non-root user
USER appuser

# Set environment variables
ENV PYTHONUNBUFFERED=1
ENV PYTHONDONTWRITEBYTECODE=1

# Health check to ensure the container is running properly
HEALTHCHECK --interval=60s --timeout=10s --retries=3 CMD \
  wget -qO- $GLUETUN_URL | grep -q '"port":' || exit 1

# Run the application
CMD ["python", "update-port-helper.py"]