<?php

namespace App\Domain\Orders\Enums;

/**
 * Where a car is in the wash. Moves forward through the queue, can step back for rework,
 * and ends delivered or cancelled.
 */
enum OrderStatus: string
{
    case Waiting = 'waiting';
    case InProgress = 'in_progress';
    case QualityCheck = 'qc';
    case Ready = 'ready';
    case Delivered = 'delivered';
    case Cancelled = 'cancelled';

    /**
     * @return list<self>
     */
    public function allowedNext(): array
    {
        return match ($this) {
            self::Waiting => [self::InProgress, self::Cancelled],
            self::InProgress => [self::QualityCheck, self::Ready, self::Waiting, self::Cancelled],
            self::QualityCheck => [self::Ready, self::InProgress, self::Cancelled],
            self::Ready => [self::Delivered, self::InProgress],
            self::Delivered, self::Cancelled => [],
        };
    }

    public function canMoveTo(self $next): bool
    {
        return in_array($next, $this->allowedNext(), true);
    }

    /**
     * Still in the queue (not delivered or cancelled).
     */
    public function isActive(): bool
    {
        return ! in_array($this, [self::Delivered, self::Cancelled], true);
    }

    /**
     * A car is physically in a bay in these states, so the bay is busy.
     */
    public function occupiesBay(): bool
    {
        return in_array($this, [self::InProgress, self::QualityCheck], true);
    }

    /**
     * The order column stamped when the order reaches this status.
     */
    public function timestampColumn(): ?string
    {
        return match ($this) {
            self::Waiting => null,
            self::InProgress => 'started_at',
            self::QualityCheck => 'qc_at',
            self::Ready => 'ready_at',
            self::Delivered => 'delivered_at',
            self::Cancelled => 'cancelled_at',
        };
    }

    /**
     * @return list<string>
     */
    public static function activeValues(): array
    {
        return array_values(array_map(
            fn (self $status) => $status->value,
            array_filter(self::cases(), fn (self $status) => $status->isActive()),
        ));
    }
}
