import { Directive, HostListener, ElementRef, Input } from '@angular/core';

@Directive({
  selector: '[appKeyboardNav]',
  standalone: true
})
export class KeyboardNavDirective {
  @Input() navGroup = 'default';
  
  constructor(private el: ElementRef) {}

  @HostListener('keydown', ['$event'])
  handleKeyDown(event: KeyboardEvent): void {
    const element = this.el.nativeElement;
    
    switch (event.key) {
      case 'ArrowDown':
        event.preventDefault();
        this.focusNext(element);
        break;
        
      case 'ArrowUp':
        event.preventDefault();
        this.focusPrevious(element);
        break;
        
      case 'Home':
        event.preventDefault();
        this.focusFirst(element);
        break;
        
      case 'End':
        event.preventDefault();
        this.focusLast(element);
        break;
        
      case 'Enter':
      case ' ':
        // Let enter/space trigger click
        if (element.tagName !== 'INPUT' && element.tagName !== 'TEXTAREA') {
          event.preventDefault();
          element.click();
        }
        break;
    }
  }

  private getFocusableElements(container: HTMLElement): HTMLElement[] {
    const selector = 
      'a[href], button:not([disabled]), input:not([disabled]), ' +
      'select:not([disabled]), textarea:not([disabled]), ' +
      '[tabindex]:not([tabindex="-1"])';
    
    return Array.from(container.querySelectorAll(selector)) as HTMLElement[];
  }

  private focusNext(current: HTMLElement): void {
    const container = this.getContainer(current);
    const elements = this.getFocusableElements(container);
    const currentIndex = elements.indexOf(current);
    
    if (currentIndex < elements.length - 1) {
      elements[currentIndex + 1].focus();
    }
  }

  private focusPrevious(current: HTMLElement): void {
    const container = this.getContainer(current);
    const elements = this.getFocusableElements(container);
    const currentIndex = elements.indexOf(current);
    
    if (currentIndex > 0) {
      elements[currentIndex - 1].focus();
    }
  }

  private focusFirst(current: HTMLElement): void {
    const container = this.getContainer(current);
    const elements = this.getFocusableElements(container);
    
    if (elements.length > 0) {
      elements[0].focus();
    }
  }

  private focusLast(current: HTMLElement): void {
    const container = this.getContainer(current);
    const elements = this.getFocusableElements(container);
    
    if (elements.length > 0) {
      elements[elements.length - 1].focus();
    }
  }

  private getContainer(element: HTMLElement): HTMLElement {
    return element.closest('[appKeyboardNav]') || document.body;
  }
}
