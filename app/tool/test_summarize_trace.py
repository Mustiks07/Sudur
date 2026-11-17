import unittest
from summarize_trace import summarize


class TraceTest(unittest.TestCase):
    def test_separate_audio_and_wall_clocks(self):
        trace = {'droppedEvents': 0, 'events': [
            {'kind': 'captureStarted', 'wallUs': 3000000},
            {'kind': 'asrFinal', 'audioMs': 2000, 'durationUs': 200000},
            {'kind': 'WordRevealed', 'wordIndex': 78001001, 'wallUs': 4500000},
            {'kind': 'finished', 'audioMs': 2000},
        ]}
        annotation = {'words': [
            {'wordKey': '78:1:1', 'status': 'correct', 'endMs': 1000},
            {'wordKey': '78:1:2', 'status': 'correct', 'endMs': 1800},
        ]}
        result = summarize(trace, annotation)
        self.assertEqual(result['revealedLatencyP95Ms'], 500)
        self.assertEqual(result['annotatedWordsNotRevealed'], 1)
        self.assertAlmostEqual(result['decodeRatioP95'], .1)
        self.assertTrue(result['valid'])
        trace['droppedEvents'] = 1
        self.assertFalse(summarize(trace)['valid'])

    def test_incomplete_run_is_not_zero_latency(self):
        result = summarize({'droppedEvents': 0, 'events': []})
        self.assertFalse(result['valid'])
        self.assertIsNone(result['revealedLatencyP95Ms'])
        self.assertIsNone(result['decodeRatioP95'])


if __name__ == '__main__':
    unittest.main()
