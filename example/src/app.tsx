import React, { useRef, useCallback, useState, useEffect } from 'react';
import { SafeAreaView, View, Text, StyleSheet } from 'react-native';
import NSEvent from 'react-native-nsevent';
import { LogBox } from './components/log_box';
import { ToggleButton } from './components/toggle_button';
import { addLine } from './log_store';
import {
  startReportingRAF,
  cancelReportingRAF,
  Handle,
} from './tools/reporting_raf';

const deltaBuf = new Int32Array(2);

export default function App() {
  const pollingHandle = useRef<Handle | null>(null);
  const [captureOn, setCaptureOn] = useState(false);

  // Subscribe to all EventEmitters on mount
  useEffect(() => {
    const subs = [
      NSEvent.onKeyboardEvent((e) => {
        addLine(
          `[kb-evt] key=${e.keyCode} ${e.pressed ? '↓' : '↑'} shift=${e.shift} ctrl=${e.control} opt=${e.option} cmd=${e.command}`
        );
      }),
      NSEvent.onMouseButton((e) => {
        addLine(
          `[btn-evt] button=${e.button} ${e.pressed ? '↓' : '↑'} x=${e.x.toFixed(0)} y=${e.y.toFixed(0)}`
        );
      }),
      NSEvent.onScrollEvent((e) => {
        addLine(
          `[scroll-evt] dx=${e.deltaX.toFixed(1)} dy=${e.deltaY.toFixed(1)}`
        );
      }),
      NSEvent.onMouseMoveEvent((e) => {
        addLine(`[move-evt] dx=${e.deltaX} dy=${e.deltaY}`);
      }),
    ];
    addLine('[events] Subscribed to 4 EventEmitters');
    return () => {
      subs.forEach((s) => s.remove());
    };
  }, []);

  // --- EventEmitter toggles ---

  const onToggleKeyboardEvents = useCallback((on: boolean) => {
    NSEvent.toggleKeyboardEvents(on);
  }, []);

  const onToggleMouseButtonEvents = useCallback((on: boolean) => {
    NSEvent.toggleMouseButtonEvents(on);
  }, []);

  const onToggleScrollEvents = useCallback((on: boolean) => {
    NSEvent.toggleScrollEvents(on);
  }, []);

  const onToggleMouseMoveEvents = useCallback((on: boolean) => {
    NSEvent.toggleMouseMoveEvents(on);
  }, []);

  // --- Callback toggles ---

  const onToggleKeyboardCallback = useCallback((on: boolean) => {
    if (on) {
      NSEvent.registerKeyboardEventCallback(
        (keyCode, pressed, shift, control, option, command, capsLock, fn) => {
          addLine(
            `[kb-cb] key=${keyCode} ${pressed ? '↓' : '↑'} shift=${shift} ctrl=${control} opt=${option} cmd=${command} caps=${capsLock} fn=${fn}`
          );
        }
      );
    } else {
      NSEvent.registerKeyboardEventCallback(null);
    }
  }, []);

  const onToggleMouseButtonCallback = useCallback((on: boolean) => {
    if (on) {
      NSEvent.registerMouseButtonEventCallback((button, pressed, x, y) => {
        addLine(
          `[btn-cb] button=${button} ${pressed ? '↓' : '↑'} x=${x.toFixed(0)} y=${y.toFixed(0)}`
        );
      });
    } else {
      NSEvent.registerMouseButtonEventCallback(null);
    }
  }, []);

  const onToggleScrollCallback = useCallback((on: boolean) => {
    if (on) {
      NSEvent.registerScrollEventCallback((deltaX, deltaY) => {
        addLine(`[scroll-cb] dx=${deltaX.toFixed(1)} dy=${deltaY.toFixed(1)}`);
      });
    } else {
      NSEvent.registerScrollEventCallback(null);
    }
  }, []);

  const onToggleMouseMoveCallback = useCallback((on: boolean) => {
    if (on) {
      NSEvent.registerMouseMoveEventCallback((deltaX, deltaY) => {
        addLine(`[move-cb] dx=${deltaX} dy=${deltaY}`);
      });
    } else {
      NSEvent.registerMouseMoveEventCallback(null);
    }
  }, []);

  // --- Mouse delta polling ---

  const onTogglePolling = useCallback((on: boolean) => {
    if (on) {
      pollingHandle.current = startReportingRAF({
        work: () => {
          NSEvent.getMouseMoveDeltaAndReset(deltaBuf);
          const dx = deltaBuf[0];
          const dy = deltaBuf[1];
          if (dx !== 0 || dy !== 0) {
            addLine(`[poll] dx=${dx} dy=${dy}`);
          }
        },
        fpsReporter: (fps) => {
          addLine(`[poll-fps] ${fps.toFixed(0)} fps`);
        },
      });
    } else {
      if (pollingHandle.current) {
        cancelReportingRAF(pollingHandle.current);
        pollingHandle.current = null;
      }
    }
  }, []);

  // --- Capture mode ---

  const onToggleCapture = useCallback((on: boolean) => {
    if (on) {
      setCaptureOn(true);
      NSEvent.startCapture();
      NSEvent.registerKeyboardEventCallback(
        (
          keyCode,
          pressed,
          _shift,
          _control,
          _option,
          _command,
          _capsLock,
          _fn
        ) => {
          if (keyCode === 53 && pressed) {
            NSEvent.stopCapture();
            NSEvent.registerKeyboardEventCallback(null);
            setCaptureOn(false);
            addLine('[capture] Escape pressed — capture stopped');
          }
        }
      );
    } else {
      NSEvent.stopCapture();
      NSEvent.registerKeyboardEventCallback(null);
      setCaptureOn(false);
    }
  }, []);

  return (
    <SafeAreaView style={styles.container}>
      <View style={styles.controls}>
        <Text style={styles.section}>EventEmitters</Text>
        <ToggleButton
          label='Keyboard Events'
          onToggle={onToggleKeyboardEvents}
        />
        <ToggleButton
          label='Mouse Button Events'
          onToggle={onToggleMouseButtonEvents}
        />
        <ToggleButton label='Scroll Events' onToggle={onToggleScrollEvents} />
        <ToggleButton
          label='Mouse Move Events'
          onToggle={onToggleMouseMoveEvents}
        />

        <Text style={styles.section}>Callbacks</Text>
        <ToggleButton
          label='Keyboard Callback'
          onToggle={onToggleKeyboardCallback}
        />
        <ToggleButton
          label='Mouse Button Callback'
          onToggle={onToggleMouseButtonCallback}
        />
        <ToggleButton
          label='Scroll Callback'
          onToggle={onToggleScrollCallback}
        />
        <ToggleButton
          label='Mouse Move Callback'
          onToggle={onToggleMouseMoveCallback}
        />

        <Text style={styles.section}>Polling</Text>
        <ToggleButton label='Delta Polling' onToggle={onTogglePolling} />

        <Text style={styles.section}>Capture</Text>
        <ToggleButton
          label='Mouse Capture'
          onToggle={onToggleCapture}
          value={captureOn}
        />
      </View>
      <LogBox />
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: '#1a1a2e', padding: 12 },
  controls: { marginBottom: 8 },
  section: {
    color: '#6af',
    fontSize: 11,
    fontWeight: '700',
    marginTop: 8,
    marginBottom: 4,
  },
});
