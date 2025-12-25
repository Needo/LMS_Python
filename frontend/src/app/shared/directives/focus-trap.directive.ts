import { Directive, ElementRef, AfterViewInit, OnDestroy, HostListener } from '@angular/core';

@Directive({
  selector: '[appFocusTrap]',
  standalone: true
})
export class FocusTrapDirective implements AfterViewInit, OnDestroy {
  private firstFocusableElement?: HTMLElement;
  private lastFocusableElement?: HTMLElement;
  private previousActiveElement?: HTMLElement;

  constructor(private el: ElementRef) {}

  ngAfterViewInit(): void {
    this.updateFocusableElements();
    this.previousActiveElement = document.activeElement as HTMLElement;
    
    // Focus first element
    setTimeout(() => {
      if (this.firstFocusableElement) {
        this.firstFocusableElement.focus();
      }
    }, 100);
  }

  ngOnDestroy(): void {
    // Restore focus to previous element
    if (this.previousActiveElement) {
      this.previousActiveElement.focus();
    }
  }

  @HostListener('keydown', ['$event'])
  handleKeyDown(event: KeyboardEvent): void {
    if (event.key !== 'Tab') {
      return;
    }

    this.updateFocusableElements();

    if (!this.firstFocusableElement || !this.lastFocusableElement) {
      return;
    }

    if (event.shiftKey) {
      // Shift + Tab
      if (document.activeElement === this.firstFocusableElement) {
        event.preventDefault();
        this.lastFocusableElement.focus();
      }
    } else {
      // Tab
      if (document.activeElement === this.lastFocusableElement) {
        event.preventDefault();
        this.firstFocusableElement.focus();
      }
    }
  }

  private updateFocusableElements(): void {
    const focusableElements = this.getFocusableElements();
    
    if (focusableElements.length > 0) {
      this.firstFocusableElement = focusableElements[0];
      this.lastFocusableElement = focusableElements[focusableElements.length - 1];
    }
  }

  private getFocusableElements(): HTMLElement[] {
    const selector = 
      'a[href]:not([disabled]), ' +
      'button:not([disabled]), ' +
      'textarea:not([disabled]), ' +
      'input:not([disabled]), ' +
      'select:not([disabled]), ' +
      '[tabindex]:not([tabindex="-1"])';
    
    return Array.from(
      this.el.nativeElement.querySelectorAll(selector)
    ) as HTMLElement[];
  }
}
