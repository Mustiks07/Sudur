#!/usr/bin/env python3
"""Summarize metadata locally; never load audio or recognized strings."""
import argparse
import json
import math


def percentile95(values):
    return sorted(values)[math.ceil(len(values) * .95) - 1] if values else None


def summarize(trace, annotation=None, window_ms=60000):
    events = trace['events']
    failures = {'audioBacklogExceeded', 'pipelineFailed'}
    invalid = bool(trace['droppedEvents']) or any(e['kind'] in failures for e in events)
    origin = next((e['wallUs'] for e in events if e['kind'] == 'captureStarted'), None)
    end_ms = next((e['audioMs'] for e in events if e['kind'] == 'finished'), None)
    decodes = [e for e in events if e['kind'] in ('asrPartial', 'asrFinal')]
    windows = {}
    for e in decodes:
        bucket = max(0, e['audioMs'] - 1) // window_ms
        windows[bucket] = windows.get(bucket, 0) + e['durationUs'] / 1000
    ratios = []
    if end_ms:
        for bucket in range(math.ceil(end_ms / window_ms)):
            span = min(window_ms, end_ms - bucket * window_ms)
            ratios.append(windows.get(bucket, 0) / span)
    latencies = []
    missing = 0
    if annotation is not None and origin is not None:
        reveals = {}
        for e in events:
            if e['kind'] == 'WordRevealed':
                reveals.setdefault(e['wordIndex'], (e['wallUs'] - origin) / 1000)
        for word in annotation['words']:
            if word['status'] not in ('correct', 'repeated', 'selfCorrected') or word.get('endMs') is None:
                continue
            surah, ayah, position = map(int, word['wordKey'].split(':'))
            at = reveals.get(surah * 1000000 + ayah * 1000 + position)
            if at is None:
                missing += 1
            else:
                latencies.append(at - word['endMs'])
    return {
        'valid': not invalid and end_ms is not None,
        'droppedEvents': trace['droppedEvents'],
        'audioDurationMs': end_ms,
        'decodeWindowMs': window_ms,
        'decodeRatios': ratios,
        'decodeRatioP95': percentile95(ratios),
        'revealedLatencyP95Ms': percentile95(latencies),
        'annotatedWordsNotRevealed': missing,
        'negativeLatencies': sum(x < 0 for x in latencies),
        'note': 'No automatic acceptance: check WAV origin, missing words, and phone profiler results.',
    }


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('trace')
    parser.add_argument('--annotation')
    parser.add_argument('--window-ms', type=int, default=60000)
    args = parser.parse_args()
    if args.window_ms <= 0:
        parser.error('--window-ms must be positive')
    with open(args.trace, encoding='utf8') as source:
        trace = json.load(source)
    annotation = None
    if args.annotation:
        with open(args.annotation, encoding='utf8') as source:
            annotation = json.load(source)
    print(json.dumps(summarize(trace, annotation, args.window_ms), indent=2))


if __name__ == '__main__':
    main()
