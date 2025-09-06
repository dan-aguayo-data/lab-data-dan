SELECT * FROM @LAB.AI.WHISPER_APP
;
CREATE OR REPLACE STAGE LAB.AI.CODE_DUMP_STAGE;
;
DROP STAGE IF EXISTS LAB.AI.CODE_DUMP_STAGE;

;
CREATE OR REPLACE STAGE LAB.AI.CODE_DUMP_STAGE
  ENCRYPTION = (TYPE = 'SNOWFLAKE_SSE');
;
LIST @LAB.AI.WHISPER_APP;


CREATE OR REPLACE STAGE LAB.AI.CODE_DUMP_STAGE;

;
SHOW IMAGE REPOSITORIES;

;

CREATE  SERVICE AI.DUMP_IMAGE_CONTENTS
IN COMPUTE POOL PR_GPU_S
FROM SPECIFICATION $$
spec:
  containers:
    - name: dumper
      image: accountpath.registry.snowflakecomputing.com/lab/ai/image_repository_for_audio_transcription/whisper-audio2text:latest
      command: ["sh", "-c", "cp -r /app /mnt/dump && sleep 5"]
      volumeMounts:
        - name: dumpstage
          mountPath: /mnt/dump
  volumes:
    - name: dumpstage
      source: "@DUMP_STAGE"
$$;



ALTER SERVICE AI.DUMP_IMAGE_CONTENTS SUSPEND;
ALTER SERVICE AI.DUMP_IMAGE_CONTENTS RESUME;


ALTER SERVICE LAB.AI.WHISPER_AUDIO_TEXT_SVC SUSPEND;


DROP SERVICE AI.DUMP_IMAGE_CONTENTS ;
