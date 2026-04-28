(function () {
  function parseChunk(buffer, onEvent) {
    let boundary = buffer.indexOf('\n\n');
    let nextBuffer = buffer;

    while (boundary >= 0) {
      const rawEvent = nextBuffer.slice(0, boundary);
      nextBuffer = nextBuffer.slice(boundary + 2);

      let eventType = 'message';
      const dataLines = [];

      for (const line of rawEvent.split(/\r?\n/)) {
        if (line.startsWith('event:')) {
          eventType = line.slice(6).trim();
        } else if (line.startsWith('data:')) {
          dataLines.push(line.slice(5).trim());
        }
      }

      const data = dataLines.join('\n').trim();
      if (data) {
        onEvent(eventType, data);
      }

      boundary = nextBuffer.indexOf('\n\n');
    }

    return nextBuffer;
  }

  window.missionOutEventStream = {
    connect(url, accessToken, onEvent, onError) {
      const controller = new AbortController();
      const decoder = new TextDecoder();
      let closed = false;

      (async () => {
        try {
          const response = await fetch(url, {
            method: 'GET',
            headers: {
              Accept: 'text/event-stream',
              Authorization: 'Bearer ' + accessToken,
            },
            cache: 'no-store',
            signal: controller.signal,
          });

          if (!response.ok) {
            onError(String(response.status));
            return;
          }

          if (!response.body) {
            onError('missing-body');
            return;
          }

          const reader = response.body.getReader();
          let buffer = '';

          while (!closed) {
            const { value, done } = await reader.read();
            if (done) {
              break;
            }

            buffer += decoder.decode(value, { stream: true });
            buffer = parseChunk(buffer, onEvent);
          }
        } catch (error) {
          if (!closed) {
            onError(error instanceof Error ? error.message : String(error));
          }
        }
      })();

      return {
        close() {
          closed = true;
          controller.abort();
        },
      };
    },

    close(handle) {
      if (handle && typeof handle.close === 'function') {
        handle.close();
      }
    },
  };
})();
