FROM southclaws/sampctl:1.3.0-RC5

RUN \
    git clone https://github.com/Southclaws/ScavengeSurvive && \
    sampctl project build

ENTRYPOINT [ "sampctl", "run" ]
