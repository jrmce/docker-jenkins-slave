FROM node:6.10

RUN apt-get update && apt-get install -y \
    openssh-server \
    openjdk-7-jdk \
    git \
    python-yaml

# Install Chrome
RUN curl https://dl-ssl.google.com/linux/linux_signing_key.pub | apt-key add - \
    && sh -c 'echo "deb http://dl.google.com/linux/chrome/deb/ stable main" >> /etc/apt/sources.list.d/google.list' \
    && apt-get update && apt-get install -y Xvfb google-chrome-stable \
    && apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Install aws-cli
RUN curl -O https://bootstrap.pypa.io/get-pip.py \
    && python2.7 get-pip.py \
    && pip install awscli

RUN sed -i 's|session    required     pam_loginuid.so|session    optional     pam_loginuid.so|g' /etc/pam.d/sshd \
    && mkdir -p /var/run/sshd

# Add user jenkins to the image
RUN adduser --quiet jenkins \
    && echo "jenkins:jenkins" | chpasswd

ADD xvfb.sh /etc/init.d/xvfb
ADD entrypoint.sh /entrypoint.sh

RUN chmod +x /etc/init.d/xvfb \
    && chmod +x /entrypoint.sh

ENV CHROME_BIN /usr/bin/google-chrome

RUN mkdir /home/jenkins/.ssh \
    && touch /home/jenkins/.ssh/known_hosts \
    && ssh-keyscan -t rsa github.com >> /home/jenkins/.ssh/known_hosts \
    && ssh-keyscan -t rsa gitlab.com >> /home/jenkins/.ssh/known_hosts\ \
    && mkdir /home/jenkins/.aws \
    && touch /home/jenkins/.aws/credentials \
    && echo "[default]" >> /home/jenkins/.aws/credentials \
    && chown -R jenkins:jenkins /home/jenkins/.aws \
    && echo "DISPLAY=:99" >> /etc/environment

# Standard SSH port
EXPOSE 22

ENTRYPOINT ["/entrypoint.sh"]
CMD ["/usr/sbin/sshd", "-D"]