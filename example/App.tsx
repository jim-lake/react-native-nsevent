import React, { useState, useRef, useEffect, useCallback } from 'react';
import {
  SafeAreaView,
  ScrollView,
  View,
  Text,
  Pressable,
  StyleSheet,
} from 'react-native';
import {
  registerEventCallback,
  startCapture,
  stopCapture,
  getMouseAndReset,
  NSEventEvent,
} from 'react-native-nsevent';

const MAX_LOG = 200;

export default function App() {
  const [events, setEvents] = useState<string[]>([]);
  const scrollRef = useRef<ScrollView>(null);
  const timerRef = useRef<ReturnType<typeof setInterval> | null>(null);

  const addLog = useCallback((entry: string) => {
    setEvents((prev) => {
      const next = [...prev, entry];
      return next.length > MAX_LOG ? next.slice(-MAX_LOG) : next;
    });
  }, []);

  const doStartCapture = useCallback(() => {
    startCapture();
    timerRef.current = setInterval(() => {
      const { dx, dy } = getMouseAndReset();
      addLog(`[mouse] dx=${dx} dy=${dy}`);
    }, 1000);
  }, [addLog]);

  const doStopCapture = useCallback(() => {
    stopCapture();
    if (timerRef.current) {
      clearInterval(timerRef.current);
      timerRef.current = null;
    }
  }, []);

  const cb = useCallback(
    (event: NSEventEvent) => {
      // Escape key stops capture
      if (
        event.type === 'keyDown' &&
        'keyCode' in event &&
        event.keyCode === 53
      ) {
        doStopCapture();
      }
      addLog(`[${event.type}] ${JSON.stringify(event)}`);
    },
    [addLog, doStopCapture]
  );

  useEffect(() => {
    registerEventCallback(cb);
    return () => registerEventCallback(null);
  }, [cb]);

  return (
    <SafeAreaView style={styles.container}>
      <View style={styles.header}>
        <Text style={styles.title}>NSEvent Capture</Text>
        <View style={styles.buttons}>
          <Pressable
            accessibilityLabel='register-btn'
            testID='register-btn'
            style={styles.button}
            onPress={() => registerEventCallback(cb)}
          >
            <Text style={styles.buttonText}>Register</Text>
          </Pressable>
          <Pressable
            accessibilityLabel='unregister-btn'
            testID='unregister-btn'
            style={styles.button}
            onPress={() => registerEventCallback(null)}
          >
            <Text style={styles.buttonText}>Unregister</Text>
          </Pressable>
          <Pressable
            accessibilityLabel='start-capture-btn'
            testID='start-capture-btn'
            style={styles.button}
            onPress={doStartCapture}
          >
            <Text style={styles.buttonText}>Start Capture</Text>
          </Pressable>
          <Pressable
            accessibilityLabel='stop-capture-btn'
            testID='stop-capture-btn'
            style={styles.button}
            onPress={doStopCapture}
          >
            <Text style={styles.buttonText}>Stop Capture</Text>
          </Pressable>
        </View>
      </View>
      <ScrollView
        accessibilityLabel='event-log'
        testID='event-log'
        ref={scrollRef}
        style={styles.log}
        onContentSizeChange={() => scrollRef.current?.scrollToEnd()}
      >
        {events.map((entry, i) => (
          <Text
            key={i}
            accessibilityLabel='log-entry'
            testID='log-entry'
            style={styles.logEntry}
          >
            {entry}
          </Text>
        ))}
      </ScrollView>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: '#1a1a2e' },
  header: { padding: 16 },
  title: {
    fontSize: 20,
    fontWeight: 'bold',
    color: '#e0e0e0',
    marginBottom: 12,
  },
  buttons: { flexDirection: 'row', gap: 12 },
  button: {
    backgroundColor: '#16213e',
    paddingHorizontal: 16,
    paddingVertical: 10,
    borderRadius: 6,
    borderWidth: 1,
    borderColor: '#0f3460',
  },
  buttonText: { color: '#e0e0e0', fontWeight: '600' },
  log: {
    flex: 1,
    backgroundColor: '#0f0f1a',
    margin: 16,
    borderRadius: 8,
    padding: 12,
  },
  logEntry: {
    color: '#8f8',
    fontFamily: 'Menlo',
    fontSize: 11,
    marginBottom: 2,
  },
});
