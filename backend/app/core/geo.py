import math
from typing import Iterable, Tuple

EARTH_RADIUS_METERS = 6_371_000.0


def haversine_meters(lat1: float, lng1: float, lat2: float, lng2: float) -> float:
    phi1 = math.radians(lat1)
    phi2 = math.radians(lat2)
    dphi = math.radians(lat2 - lat1)
    dlambda = math.radians(lng2 - lng1)
    a = math.sin(dphi / 2) ** 2 + math.cos(phi1) * math.cos(phi2) * math.sin(dlambda / 2) ** 2
    c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a))
    return EARTH_RADIUS_METERS * c


def total_path_meters(points: Iterable[Tuple[float, float]]) -> float:
    """좌표 시퀀스(lat, lng)의 누적 거리(미터)."""
    iterator = iter(points)
    try:
        prev = next(iterator)
    except StopIteration:
        return 0.0
    total = 0.0
    for curr in iterator:
        total += haversine_meters(prev[0], prev[1], curr[0], curr[1])
        prev = curr
    return total
