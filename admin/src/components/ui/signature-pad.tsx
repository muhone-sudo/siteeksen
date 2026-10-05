"use client";

import { useEffect, useRef, useState } from "react";

/**
 * Dokunmatik/fare imza alanı. Çizim bittiğinde PNG `Blob` döner; boş alan `null`.
 * Harici paket kullanılmaz (canvas + pointer olayları).
 */
export function SignaturePad({ onChange, height = 160 }: { onChange: (png: Blob | null) => void; height?: number }) {
    const ref = useRef<HTMLCanvasElement>(null);
    const drawing = useRef(false);
    const [empty, setEmpty] = useState(true);

    useEffect(() => {
        const c = ref.current;
        if (!c) return;
        const ratio = window.devicePixelRatio || 1;
        c.width = c.offsetWidth * ratio;
        c.height = height * ratio;
        const ctx = c.getContext("2d");
        if (!ctx) return;
        ctx.scale(ratio, ratio);
        ctx.lineWidth = 2;
        ctx.lineCap = "round";
        ctx.strokeStyle = "#111827";
    }, [height]);

    const point = (e: React.PointerEvent<HTMLCanvasElement>) => {
        const r = e.currentTarget.getBoundingClientRect();
        return { x: e.clientX - r.left, y: e.clientY - r.top };
    };
    const finish = () => {
        if (!drawing.current) return;
        drawing.current = false;
        ref.current?.toBlob((b) => onChange(b), "image/png");
    };
    const clear = () => {
        const c = ref.current;
        c?.getContext("2d")?.clearRect(0, 0, c.width, c.height);
        setEmpty(true);
        onChange(null);
    };

    return (
        <div>
            <canvas
                ref={ref}
                aria-label="İmza alanı"
                style={{ height, touchAction: "none" }}
                className="w-full rounded-lg border border-dashed border-gray-400 bg-white"
                onPointerDown={(e) => {
                    const ctx = e.currentTarget.getContext("2d");
                    const p = point(e);
                    drawing.current = true;
                    setEmpty(false);
                    ctx?.beginPath();
                    ctx?.moveTo(p.x, p.y);
                    e.currentTarget.setPointerCapture(e.pointerId);
                }}
                onPointerMove={(e) => {
                    if (!drawing.current) return;
                    const ctx = e.currentTarget.getContext("2d");
                    const p = point(e);
                    ctx?.lineTo(p.x, p.y);
                    ctx?.stroke();
                }}
                onPointerUp={finish}
                onPointerLeave={finish}
            />
            <div className="mt-1 flex justify-between text-xs text-gray-500">
                <span>{empty ? "Teslim alan kişi parmağı ya da fareyle imzalasın" : "İmza alındı"}</span>
                <button type="button" className="text-primary hover:underline" onClick={clear}>Temizle</button>
            </div>
        </div>
    );
}
